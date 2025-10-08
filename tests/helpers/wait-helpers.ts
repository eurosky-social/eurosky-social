import { setTimeout as sleep } from 'timers/promises';

export async function waitForCondition<T>(
  checkFn: () => Promise<T>,
  predicate: (result: T) => boolean,
  options: { timeout: number; interval?: number }
): Promise<T> {
  const interval = options.interval ?? 500;
  const startTime = Date.now();

  while (true) {
    const result = await checkFn();

    if (predicate(result)) {
      return result;
    }

    const elapsed = Date.now() - startTime;
    if (elapsed >= options.timeout) {
      throw new Error(`Timeout waiting for condition after ${options.timeout}ms`);
    }

    const remainingTime = options.timeout - elapsed;
    const waitTime = Math.min(interval, remainingTime);
    await sleep(waitTime);
  }
}

export class EventBuffer<T> {
  private events: T[] = [];
  private waiters: Array<{
    predicate: (event: T) => boolean;
    resolve: (event: T) => void;
    reject: (error: Error) => void;
    timeout: NodeJS.Timeout;
  }> = [];

  add(event: T): void {
    this.events.push(event);

    this.waiters = this.waiters.filter((waiter) => {
      if (waiter.predicate(event)) {
        clearTimeout(waiter.timeout);
        waiter.resolve(event);
        return false;
      }
      return true;
    });
  }

  waitFor(predicate: (event: T) => boolean, timeout: number): Promise<T> {
    const existingEvent = this.events.find(predicate);
    if (existingEvent) {
      return Promise.resolve(existingEvent);
    }

    return new Promise<T>((resolve, reject) => {
      const timeoutHandle = setTimeout(() => {
        this.waiters = this.waiters.filter((w) => w.resolve !== resolve);
        reject(new Error(`Timeout waiting for event after ${timeout}ms`));
      }, timeout);

      this.waiters.push({
        predicate,
        resolve,
        reject,
        timeout: timeoutHandle,
      });
    });
  }

  getAll(): T[] {
    return [...this.events];
  }

  clear(): void {
    this.events = [];
  }
}
