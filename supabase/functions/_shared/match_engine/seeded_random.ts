/** Deterministic PRNG — Mulberry32. Always inject; never Math.random in engine. */

export class SeededRandom {
  private state: number;

  constructor(seed: number) {
    // Ensure non-zero 32-bit state
    this.state = (seed >>> 0) || 1;
  }

  /** [0, 1) */
  next(): number {
    let t = (this.state += 0x6d2b79f5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }

  /** Inclusive integer range */
  int(min: number, max: number): number {
    return min + Math.floor(this.next() * (max - min + 1));
  }

  bool(probability: number): boolean {
    return this.next() < probability;
  }

  pick<T>(items: readonly T[]): T {
    if (items.length === 0) {
      throw new Error("SeededRandom.pick: empty array");
    }
    return items[Math.floor(this.next() * items.length)]!;
  }

  /** Poisson-ish count via Knuth for small λ */
  poisson(lambda: number): number {
    if (lambda <= 0) return 0;
    const L = Math.exp(-lambda);
    let k = 0;
    let p = 1;
    do {
      k++;
      p *= this.next();
    } while (p > L && k < 40);
    return k - 1;
  }
}
