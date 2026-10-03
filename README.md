# Data Warehouse — Óptica

Proyecto de integración, transformación y almacenamiento de datos para una óptica, desarrollado mediante un proceso ETL utilizando MySQL.

## Descripción

El proyecto implementa un flujo de procesamiento de datos desde una base de datos de origen hacia una capa de **staging**, donde los datos son preparados y limpiados antes de ser cargados a un **Data Warehouse**.

El objetivo es centralizar la información y organizarla mediante un modelo dimensional que facilite posteriormente la consulta y el análisis de información del negocio.

## Arquitectura

```text
Fuente de datos
      │
      ▼
   Staging
      │
      ▼
Transformación
y limpieza
      │
      ▼
Data Warehouse
      │
      ▼
Modelo dimensional
```

## Proceso ETL

### 1. Extracción

Se prepara la base de datos de staging para recibir la información proveniente de las fuentes de datos.

### 2. Transformación y limpieza

Se realizan procesos de preparación y limpieza de los datos para adecuarlos a las estructuras requeridas por el Data Warehouse.

### 3. Carga

Los datos transformados son cargados al Data Warehouse mediante un modelo dimensional.

## Modelo dimensional

Entre las dimensiones implementadas se encuentran:

* Dimensión Tiempo
* Dimensión Cliente
* Dimensión Producto
* Dimensión Vendedor

El modelo también contempla índices para facilitar el acceso y las consultas sobre los datos.

## Tecnologías

* MySQL 8
* SQL
* ETL
* Data Warehouse
* Modelo dimensional

## Estructura del proyecto

```text
DW-Optica/
├── README.md
└── sql/
    ├── 01_extraccion_staging.sql
    ├── 02_transformacion_limpieza.sql
    └── 03_carga_datawarehouse.sql
```

## Ejecución

Los scripts deben ejecutarse utilizando **MySQL 8** respetando el siguiente orden:

1. `01_extraccion_staging.sql`
2. `02_transformacion_limpieza.sql`
3. `03_carga_datawarehouse.sql`

> Los archivos SQL originales utilizados durante el desarrollo contienen dumps completos de las bases de datos de staging y del Data Warehouse. Estos archivos no se incluyen en el repositorio para mantenerlo ligero y enfocado en los scripts reproducibles del proceso ETL.

## Objetivo del proyecto

Aplicar conceptos de integración de datos, procesos ETL, limpieza de información y diseño de Data Warehouse mediante SQL, utilizando un modelo dimensional orientado al análisis de información de una óptica.

## Estado

Proyecto académico finalizado.
