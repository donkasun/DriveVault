import { NextResponse } from 'next/server';
import { ZodError } from 'zod';

export class AppError extends Error {
  readonly status: number;
  readonly detail: string;

  constructor(status: number, detail: string) {
    super(detail);
    this.status = status;
    this.detail = detail;
    this.name = 'AppError';
  }
}

export function toErrorResponse(err: unknown): NextResponse {
  if (err instanceof AppError) {
    return NextResponse.json({ detail: err.detail }, { status: err.status });
  }

  if (err instanceof ZodError) {
    const detail = err.issues
      .map((issue) => `${issue.path.join('.') || '(body)'}: ${issue.message}`)
      .join('; ');
    return NextResponse.json({ detail }, { status: 400 });
  }

  console.error(err);
  return NextResponse.json({ detail: 'Internal server error' }, { status: 500 });
}
