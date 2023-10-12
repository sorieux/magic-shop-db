# magic-store-db

This project sets up a Dockerized PostgreSQL database for a fictitious magic shop inspired by the Harry Potter universe. The database is initialized with sample data from CSV files.

The goal of this database is to provide a fun and easy-to-set-up data source for demonstrations or tests. I hope it can be of help to you, and please don't hesitate to share with me how you've made use of it.

## Prerequisites

- Docker
- Docker Compose

## Setup & Running

1. Clone the repository:

```
git clone https://github.com/sorieux/magic-shop-db.git
```

2. Navigate to the project directory:

```
cd magic-shop-db
```

3. Start the PostgreSQL container:

```
docker compose up

```

![It's Magic !!!](https://media.tenor.com/kKX3uh8mm_kAAAAC/i-love-magic-magical.gif)

## Accessing the Database

Once the container is running, you can access the PostgreSQL database using any SQL client with the following credentials:

**Host:** localhost  
**Port:** 5432  
**User:** harry  
**Password:** potter  
**Database:** magic-shop

## Contributing

If you wish to contribute, please fork the repository and use a feature branch. Pull requests are warmly welcome.
