{{
  config(
    materialized = 'incremental',
    unique_key='uuid',
    on_schema_change='append_new_columns',
    indexes=[
      {'columns': ['uuid'], 'type': 'hash'},
      {'columns': ['saved_timestamp'], 'type': 'btree'},
      {'columns': ['patient_id'], 'type': 'hash'},
    ]
  )
}}

SELECT 
    p.uuid AS patient_uuid,
    c.name,
    d.doc->'sms_message'->>'from' AS phone,
    d.doc->'form' AS form,
    TO_TIMESTAMP((doc->>'reported_date')::bigint / 1000) AS reported,
    d.doc->'sms_message'->>'message' AS message
FROM 
    {{ ref('contact') }} 
JOIN 
    patient p ON c.uuid = p.uuid
JOIN 
    {{ env_var('POSTGRES_SCHEMA') }}.{{ env_var('POSTGRES_TABLE') }} d ON d.doc->'sms_message'->>'from' IN (c.phone, c.phone2)
WHERE 
    d.doc->'sms_message'->>'message' IS NOT NULL
{% if is_incremental() %}
  AND c.saved_timestamp >= {{ max_existing_timestamp('saved_timestamp') }}
{% endif %}