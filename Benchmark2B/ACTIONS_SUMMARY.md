# Benchmark2B Actions Summary

This document lists testable page routes and their database actions (Create, Read, Update, Delete).

## Authentication and Accounts

- `/LoginPortal`:
  - Read: validates user credentials from `users` table.
- `/CreateAccount`:
  - Create: inserts into `users`.
  - Create: inserts linked `clients` record for new client signup.

## Client Portal Pages

- `/client/overview`:
  - Read: invoices (`/invoices`).
  - Read: client service requests (`/api/client/service-requests`).
  - Read: appointments (`/appointments` or `/api/client/appointments`).
  - Read: client locations (`/api/client/locations`).

- `/service-request.html`:
  - Read: services catalog (`/services`).
  - Read: client locations (`/api/client/locations`).
  - Create: new service request (`/api/client/service-requests`).

- `/appointments.html`:
  - Read: client appointments and pending requests (`/api/client/appointments`).

- `/invoices.html`:
  - Read: client invoice list (`/invoices`).

- `/profile.html`:
  - Read: profile (`/api/client/profile`).
  - Update: profile (`/api/client/profile`, PUT).
  - Read: locations (`/api/client/locations`).
  - Create: location (`/api/client/locations`, POST).
  - Delete (soft): location (`/api/client/locations/<id>`, DELETE sets inactive).

## Management Portal Pages

- `/management` (employees):
  - Read: employees (`/employees`).
  - Read: employee stats (`/api/management/employee-stats`).
  - Create: employee/user (`/user`, POST).
  - Update (soft delete): deactivate user (`/user/<id>`, DELETE sets inactive).
  - Update: reactivate user (`/user/<id>/reactivate`, POST).
  - Update: employee fields (`/api/employees/<id>`, PATCH).
  - Read: assignable jobs (`/api/management/employees/<employee_id>/assignable-jobs`).
  - Update: assign/reassign job (`/jobs/<job_id>/assign`, POST).

- `/clients.html`:
  - Read: clients (`/api/clients`).
  - Create: new client and linked contact user (`/api/clients`, POST).
  - Update: client details (`/api/clients/<id>`, PUT).
  - Update (soft delete): deactivate client (`/api/clients/<id>/deactivate`, POST).
  - Update: reactivate client (`/api/clients/<id>/reactivate`, POST).
  - Read: client locations (`/api/clients/<id>/locations`).

- `/scheduling.html`:
  - Read: jobs list (`/jobs`).
  - Read: available employees by time window (`/api/management/available-employees`).
  - Update: assign/reassign (`/jobs/<job_id>/assign`, POST).

- `/suppliers.html`:
  - Read: suppliers (`/suppliers`).
  - Create: supplier (`/suppliers`, POST).
  - Update: supplier (`/api/suppliers/<id>`, PUT).
  - Update (soft delete): deactivate (`/suppliers/<id>/deactivate`, POST).
  - Update: reactivate (`/suppliers/<id>/reactivate`, POST).

- `/inventory.html`:
  - Read: inventory (`/api/inventory`, GET).
  - Create: inventory item (`/api/inventory`, POST).
  - Update: stock quantity (`/api/inventory/<item_id>/stock`, PATCH).
  - Update: reorder operation (`/api/inventory/<item_id>/reorder`, POST).
  - Update: edit item fields (`/api/inventory/<item_id>`, PUT).
  - Delete (soft): remove item (`/api/inventory/<item_id>`, DELETE sets inactive).
  - Read: material requests (`/api/management/material-requests`).
  - Update: approve/reject material request (`/api/management/material-requests/<id>/approve|reject`).
  - Read: material usage logs (`/api/management/material-usage`).

- `/services.html`:
  - Read: service catalog (`/services`, GET).
  - Create: service (`/services`, POST).
  - Update: service (`/services/<id>`, PUT).
  - Update (soft delete): deactivate service (`/services/<id>/deactivate`, POST).
  - Update: reactivate service (`/services/<id>/reactivate`, POST).

- `/job-order.html`:
  - Read: management service requests (`/api/management/service-requests`).
  - Update: approve request + create job order (`/api/management/service-requests/<id>/approve`, POST).
  - Update: reject request (`/api/management/service-requests/<id>/reject`, POST).
  - Read: jobs (`/jobs`).
  - Update: cancel job (`/api/management/job-orders/<id>/cancel`, POST).

- `/plant-master.html`:
  - Read: plant master entries (`/api/plant_master`, GET).
  - Create: plant entry (`/api/plant_master`, POST).
  - Update: plant entry (`/api/plant_master/<id>`, PUT).
  - Delete (soft): plant entry (`/api/plant_master/<id>`, DELETE sets inactive).

## Staff Portal Pages

- `/staff-scheduling-dashboard.html`:
  - Read: personal schedule events (`/staff/schedule/events`).
  - Read: personal weekly availability (`/availability/my`).
  - Read/Update: skills (`/staff/skills/my`, GET/POST).
  - Create/Update: availability submission (`/availability`, POST).

- `/task-management-dashboard.html`:
  - Read: assigned tasks rendered from DB query in backend route.

- `/inventory-dashboard.html`:
  - Uses staff inventory/material routes for read and submission workflows.

## Quick Demo Flow for Presentation

1. Log in via `/LoginPortal` as Management.
2. Go to `/services.html` and create a service (Create).
3. Go to `/inventory.html` and add item + adjust stock (Create + Update).
4. Go to `/clients.html` and create or update a client (Create + Update).
5. Log in as Client and submit `/service-request.html` (Create).
6. Return as Management and approve in `/job-order.html` (Update + Create job order).
7. Show client appointment appears in `/appointments.html` (Read).

## Submission Notes

- Include this file and `CREDENTIALS.txt` in root of `Benchmark2B`.
- Include `Planted_Database.sql` as self-contained export.
- Keep folder structure exactly as used locally.
