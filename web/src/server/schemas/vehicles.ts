import { z } from 'zod';

const FUEL_TYPES = ['petrol', 'diesel', 'electric', 'hybrid', 'other'] as const;

/** Derived document-expiry health for a vehicle (Doc 3). */
export const docsStatusSchema = z.object({
  state: z.enum(['none', 'valid', 'needs_action']),
  needsActionCount: z.number().int().nonnegative(),
});

export type DocsStatus = z.infer<typeof docsStatusSchema>;

const vehicleFields = {
  make: z.string().min(1),
  model: z.string().min(1),
  year: z.number().int().min(1900).max(2100).nullable().optional(),
  registrationNumber: z.string().nullable().optional(),
  vin: z.string().nullable().optional(),
  purchaseDate: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'purchaseDate must be YYYY-MM-DD')
    .nullable()
    .optional(),
  purchasePriceCents: z.number().int().nullable().optional(),
  currency: z
    .string()
    .regex(/^[A-Za-z]{3}$/, 'currency must be a 3-letter code')
    .optional(),
  currentMileage: z.number().int().nullable().optional(),
  vehicleType: z.string().nullable().optional(),
  fuelType: z.enum(FUEL_TYPES).nullable().optional(),
  distanceUnit: z.enum(['km', 'mi']).nullable().optional(),
  photoUrl: z.string().nullable().optional(),
  photoPublicId: z.string().nullable().optional(),
};

/** POST /api/v1/vehicles — make + model required. */
export const createVehicleSchema = z.object(vehicleFields);

export type CreateVehicle = z.infer<typeof createVehicleSchema>;

/** PATCH /api/v1/vehicles/{id} — all fields optional. */
export const updateVehicleSchema = z.object({
  make: z.string().min(1).optional(),
  model: z.string().min(1).optional(),
  year: z.number().int().min(1900).max(2100).nullable().optional(),
  registrationNumber: z.string().nullable().optional(),
  vin: z.string().nullable().optional(),
  purchaseDate: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'purchaseDate must be YYYY-MM-DD')
    .nullable()
    .optional(),
  purchasePriceCents: z.number().int().nullable().optional(),
  currency: z
    .string()
    .regex(/^[A-Za-z]{3}$/, 'currency must be a 3-letter code')
    .optional(),
  currentMileage: z.number().int().nullable().optional(),
  vehicleType: z.string().nullable().optional(),
  fuelType: z.enum(FUEL_TYPES).nullable().optional(),
  distanceUnit: z.enum(['km', 'mi']).nullable().optional(),
  photoUrl: z.string().nullable().optional(),
  photoPublicId: z.string().nullable().optional(),
});

export type UpdateVehicle = z.infer<typeof updateVehicleSchema>;

/** Wire shape for Vehicle responses (Doc 3). */
export const vehicleResponseSchema = z.object({
  id: z.string().uuid(),
  make: z.string(),
  model: z.string(),
  year: z.number().nullable(),
  registrationNumber: z.string().nullable(),
  vin: z.string().nullable(),
  purchaseDate: z.string().nullable(),
  purchasePriceCents: z.number().nullable(),
  currency: z.string(),
  currentMileage: z.number().nullable(),
  vehicleType: z.string().nullable(),
  fuelType: z.string().nullable(),
  distanceUnit: z.enum(['km', 'mi']).nullable(),
  photoUrl: z.string().nullable(),
  photoPublicId: z.string().nullable(),
  createdAt: z.string(),
  updatedAt: z.string(),
  docsStatus: docsStatusSchema,
});

export type VehicleResponse = z.infer<typeof vehicleResponseSchema>;
