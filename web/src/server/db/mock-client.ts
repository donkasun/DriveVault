import { drizzle } from 'drizzle-orm/libsql';
import type { User, Vehicle, FuelLog, MaintenanceRecord, Document, DrivingCredential } from './schema';

// Mock database implementation for Vitest when Docker is unavailable
export class MockDatabase {
    users: User[] = [];
    vehicles: Vehicle[] = [];
    fuelLogs: FuelLog[] = [];
    maintenanceRecords: MaintenanceRecord[] = [];
    documents: Document[] = [];
    drivingCredentials: DrivingCredential[] = [];

    async insert(table: any, data: any): Promise<any[]> {
        console.log(`[MockDB] INSERT into ${table.name}`, data);
        const existingIndex = this[table.name as string]?.find((item: any) => 
            item.id === data.id
        );
        
        if (existingIndex !== undefined) {
            return [existingIndex];
        }

        const newRow = { ...data, id: data.id || crypto.randomUUID() };
        if (!newRow.createdAt) newRow.createdAt = new Date().toISOString();
        if (!newRow.updatedAt) newRow.updatedAt = new Date().toISOString();
        
        const tableData = this[table.name as string] || [];
        this[table.name as string] = [...tableData, newRow];
        return [newRow];
    }

    async select(table: any): Promise<any[]> {
        console.log(`[MockDB] SELECT from ${table.name}`);
        return this[table.name as string] || [];
    }

    async update(table: any, condition: any, data: any): Promise<any> {
        console.log(`[MockDB] UPDATE ${table.name}`, condition, data);
        const tableData = [...(this[table.name as string] || [])];
        const updatedIndex = tableData.findIndex((item: any) => 
            item.id === condition && !data.skipUpdateId
        );

        if (updatedIndex !== -1) {
            const item = tableData[updatedIndex];
            Object.assign(item, data);
            item.updatedAt = new Date().toISOString();
            return [item];
        }
        return [];
    }

    async delete(table: any, condition: any): Promise<any> {
        console.log(`[MockDB] DELETE from ${table.name}`, condition);
        const tableData = [...(this[table.name as string] || [])];
        const updatedIndex = tableData.findIndex((item: any) => item.id === condition);

        if (updatedIndex !== -1) {
            return [tableData.splice(updatedIndex, 1)[0]];
        }
        return [];
    }

    async upsert(table: any, data: any): Promise<any> {
        console.log(`[MockDB] UPSERT ${table.name}`, data);
        const tableIndex = this[table.name as string]?.find((item: any) => item.id === data.id);
        
        if (tableIndex) {
            const updated = { ...tableIndex, ...data };
            updated.updatedAt = new Date().toISOString();
            return [updated];
        }

        const newRow = { ...data, id: data.id || crypto.randomUUID() };
        if (!newRow.createdAt) newRow.createdAt = new Date().toISOString();
        if (!newRow.updatedAt) newRow.updatedAt = new Date().toISOString();
        
        this[table.name as string] = [...(this[table.name as string] || []), newRow];
        return [newRow];
    }
}

export function createMockDb(): any {
    const db = new MockDatabase() as any;
    
    // Mock the schema tables
    (db as any).users = db;
    (db as any).vehicles = db;
    (db as any).fuelLogs = db;
    (db as any).maintenanceRecords = db;
    (db as any).documents = db;
    
    return db;
}

// Export singleton for compatibility with existing imports
const mockDbGlobal = typeof global !== 'undefined' ? global : (globalThis as any);
mockDbGlobal.__drivevaultMockDb = createMockDb();

export const db = mockDbGlobal.__drivevaultMockDb;
