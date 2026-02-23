{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}

    {%- if custom_schema_name is none -%}
        {{ default_schema }}

    {%- elif target.name == 'prod' -%}
        {# In prod use the custom schema name directly (e.g. silver, gold) #}
        {{ custom_schema_name | trim }}

    {%- else -%}
        {# In dev/ci prefix with the target dataset (e.g. dev_silver, dbt_ci_pr42_gold) #}
        {{ default_schema }}_{{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}
