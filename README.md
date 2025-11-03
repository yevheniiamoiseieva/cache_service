#  Cache Service (High-Speed Data Layer)

## Overview and Purpose

I developed the Cache Service as a specialized microservice designed solely for **fast, scalable indexing and data retrieval**. Its core function is to act as a high-speed layer built on **Elasticsearch** that the Event Service relies on to reduce read latency.

This service implements the public API for all external cache operations, ensuring stability and performance under load.

---

## Technical Design & Resilience

### 1. Elasticsearch as the Indexed Cache Store

* **Indexing Strategy:** The service accepts structured event data and indexes it using Elasticsearch. My custom mapping is optimized to support efficient **full-text search** (e.g., in the event description) and fast, **case-insensitive sorting** by title and date.
* **Consistency:** The writer logic utilizes the Elasticsearch **Bulk API** and is configured to ensure **immediate data visibility** (`refresh: true`) after a successful write operation.
* **Schema Management:** I use **Index Versioning** and **Logical Aliases** to reference the data structure. This design allows me to update the underlying index schema (e.g., from V1 to V2) without requiring the Event Service to ever go offline.

### 2. High-Performance Architecture

* **Concurrency Control (Singleton):** The application relies on a strict **Singleton pattern** for its `ElasticConnector`, which manages the secure `ConnectionPool`.
* **Performance:** The **Connection Pool** provides a fixed number of dedicated connections to Elasticsearch, ensuring the service is **thread-safe** and prevents resource exhaustion under heavy, concurrent load from the web server (Puma).

### 3. API Endpoints

The API is simple and robust, serving as the interface for the Event Service's caching strategy:

| Method | Role |
| :--- | :--- |
| `POST /cache/events` | **Write-Through endpoint.** Receives new or updated event data from the Event Service for indexed storage. |
| `GET /cache/events/:id` | **Read-Through endpoint.** Executes a rapid lookup by ID and returns the cached document or a `404` (Cache MISS). |

---

## Deployment and Tools

* **Platform:** Ruby (Roda) micro-framework, running on Puma.
* **Storage Engine:** Elasticsearch.
* **Inter-Service Communication:** The service resides in a dedicated Docker Compose stack but connects to the Event Service via a **shared external network**, resolving hostnames like `http://event_service:3000`.
