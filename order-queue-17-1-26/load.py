import asyncio
import aiohttp
import random
import string
import time

API_URL = "LAMBDA_TRIGGER_API_URL_HERE"

TOTAL_REQUESTS = 500
BATCH_SIZE = 50
DELAY_BETWEEN_BATCHES = 0  # seconds
CONCURRENCY = 10


def random_email():
    return "".join(random.choices(string.ascii_lowercase, k=6)) + "@test.com"


def generate_order():
    return {
        "email": random_email(),
        "items": [
            {
                "sku": "BOOK-001",
                "qty": random.randint(1, 3)
            }
        ]
    }


async def send_order(session, order_id):
    try:
        async with session.post(API_URL, json=generate_order()) as response:
            text = await response.text()
            print(f"✅ [{order_id}] {response.status}")
    except Exception as e:
        print(f"❌ [{order_id}] Error: {str(e)}")


async def worker(semaphore, session, order_id):
    async with semaphore:
        await send_order(session, order_id)


async def send_batch(session, semaphore, start_id, end_id):
    tasks = [
        worker(semaphore, session, i)
        for i in range(start_id, end_id)
    ]
    await asyncio.gather(*tasks)


async def main():
    start = time.time()
    semaphore = asyncio.Semaphore(CONCURRENCY)

    async with aiohttp.ClientSession() as session:
        total_batches = TOTAL_REQUESTS // BATCH_SIZE

        for batch_num in range(total_batches):
            batch_start = batch_num * BATCH_SIZE
            batch_end = batch_start + BATCH_SIZE

            # print(f"\n➡️ Sending batch {batch_num + 1}/{total_batches} "
            #       f"({batch_start} - {batch_end - 1})")

            await send_batch(session, semaphore, batch_start, batch_end)    

            # Wait before next batch if not the last one
            # if batch_num < total_batches - 1:
            #     print(f"⏳ Waiting {DELAY_BETWEEN_BATCHES}s before next batch...\n")
            #     await asyncio.sleep(DELAY_BETWEEN_BATCHES)

    duration = time.time() - start
    print(f"\n🚀 Sent {TOTAL_REQUESTS} orders in {duration:.2f} seconds")


if __name__ == "__main__":
    asyncio.run(main())

