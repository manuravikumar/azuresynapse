-- Query Event Hubs Capture AVRO files written to ADLS (raw container)
-- Replace STORAGE_ACCOUNT_NAME and PATH as needed
SELECT TOP 100 *
FROM OPENROWSET(
    BULK 'https://STORAGE_ACCOUNT_NAME.blob.core.windows.net/raw/*/*/*/*/*/*/*/*.avro',
    FORMAT = 'AVRO'
) WITH (
    transaction_id VARCHAR(50) '$.transaction_id',
    datetime       DATETIME2 '$.datetime',
    store_id       VARCHAR(10) '$.store_id',
    product_id     VARCHAR(20) '$.product_id',
    quantity       INT '$.quantity',
    unit_price     DECIMAL(10,2) '$.unit_price',
    payment_type   VARCHAR(20) '$.payment_type'
) AS eh;