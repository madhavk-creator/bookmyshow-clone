---
title: Authentication
description: Auth endpoints for users, vendors, and admins.
---

# Authentication

The API has separate auth entry points for three roles:

- `user`
- `vendor`
- `admin`

## User Auth

### Register

```http
POST /api/v1/users/register
```

### Login

```http
POST /api/v1/users/login
```

### Update Profile

```http
PATCH /api/v1/users/profile
```

### Change Password

```http
PATCH /api/v1/users/password
```

## Vendor Auth

### Register

```http
POST /api/v1/vendors/register
```

### Login

```http
POST /api/v1/vendors/login
```

### Update Profile

```http
PATCH /api/v1/vendors/profile
```

### Change Password

```http
PATCH /api/v1/vendors/password
```

## Admin Auth

### Register

```http
POST /api/v1/admin/register
```

### Login

```http
POST /api/v1/admin/login
```

### Update Profile

```http
PATCH /api/v1/admin/profile
```

### Change Password

```http
PATCH /api/v1/admin/password
```
