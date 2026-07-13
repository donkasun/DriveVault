/**
 * Resolves the liters / total / price-per-liter triple for quick fuel entry.
 * Parity with Flutter `features/fuel/domain/fuel_entry_calc.dart`.
 *
 * Only two of the three are needed; the third is derived. The two most-recently
 * edited fields are authoritative. Price-per-liter starts as a sticky default
 * (prefilled from the last log).
 *
 * `derivedField` exposes which field is currently computed so the UI can tag it
 * "AUTO". With fewer than two fields set there is no derived field.
 */

export type FuelField = 'liters' | 'total' | 'perLiter';

/** Declaration order matters: Flutter iterates `FuelField.values` to find the
 *  single unlocked field, so this array must stay liters → total → perLiter. */
const FUEL_FIELDS: FuelField[] = ['liters', 'total', 'perLiter'];

export class FuelEntryCalc {
  liters: number | null = null;
  total: number | null = null;
  pricePerLiter: number | null = null;

  /** Ordered list of the most-recently-edited fields; at most two. */
  private locked: FuelField[] = [];

  constructor(initialPerLiter?: number | null) {
    if (initialPerLiter != null && initialPerLiter > 0) {
      this.pricePerLiter = initialPerLiter;
      this.locked.push('perLiter');
    }
  }

  /** The field currently being derived (AUTO), or null when there isn't one. */
  get derivedField(): FuelField | null {
    if (this.locked.length < 2) return null;
    return FUEL_FIELDS.find((f) => !this.locked.includes(f)) ?? null;
  }

  setField(field: FuelField, value: number | null): void {
    switch (field) {
      case 'liters':
        this.liters = value;
        break;
      case 'total':
        this.total = value;
        break;
      case 'perLiter':
        this.pricePerLiter = value;
        break;
    }

    this.removeLocked(field);

    // Clearing a field unlocks it without making it authoritative.
    if (value === null) {
      this.recompute();
      return;
    }

    this.locked.push(field);

    while (this.locked.length > 2) {
      // Editing per-liter with total set evicts total (liters is kept and total
      // recomputed) — otherwise evict the oldest locked field.
      const victim =
        field === 'perLiter' && this.locked.includes('total') ? 'total' : this.locked[0];
      this.removeLocked(victim);
    }

    this.recompute();
  }

  private removeLocked(field: FuelField): void {
    const index = this.locked.indexOf(field);
    if (index !== -1) this.locked.splice(index, 1);
  }

  private recompute(): void {
    if (this.locked.length < 2) return;

    const computed = FUEL_FIELDS.find((f) => !this.locked.includes(f));

    switch (computed) {
      case 'perLiter':
        if (this.liters != null && this.liters > 0 && this.total != null) {
          this.pricePerLiter = this.total / this.liters;
        }
        break;
      case 'liters':
        if (this.total != null && this.pricePerLiter != null && this.pricePerLiter > 0) {
          this.liters = this.total / this.pricePerLiter;
        }
        break;
      case 'total':
        if (this.liters != null && this.pricePerLiter != null && this.pricePerLiter > 0) {
          this.total = this.liters * this.pricePerLiter;
        }
        break;
    }
  }

  get isComplete(): boolean {
    return this.liters != null && this.liters > 0 && this.total != null && this.total >= 0;
  }
}
