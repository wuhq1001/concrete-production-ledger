# Concrete Production Ledger

A Flutter starter application for a concrete production ledger, targeting Android, iOS, and Web from one codebase.

## Current prototype

- Chinese-language production ledger dashboard and record form.
- Capture project/site, strength grade, mix design, volume, slump, truck/operator, raw-material quantities, and notes.
- Search production records and view daily/total volume summaries.
- Demo role switcher for administrator, operator, and read-only viewer.
- Copy ledger data as CSV for spreadsheet import.
- Responsive layout suitable for mobile and desktop browsers.

## Run locally

Install Flutter, then run:

```bash
flutter pub get
flutter run -d chrome
```

For Android/iOS, select an available device in `flutter run` or create the platform folders with `flutter create --platforms=android,ios,web .` first.

## Important prototype limitations

This is the UI and workflow foundation only. It currently uses sample data held in memory; records are lost when the app restarts. The role switcher is a demonstration, not authentication or secure authorization. Before real production use, connect a backend and database, implement authenticated accounts and server-enforced permissions, and add durable storage, audit logs, backups, and tested Excel export.
