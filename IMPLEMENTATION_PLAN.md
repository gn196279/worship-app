# Gilgal Telugu Worship App - Implementation Plan

## 1. Overview

**Project Name:** Gilgal Telugu Worship App  
**Type:** Cross-platform Mobile Application (PWA-capable)  
**Content Volume:** 200+ songs (chord charts + lyrics)  
**Core Value Proposition:** Song management with role-based content filtering (Singers and Users see lyrics, Musicians see chords, Admin manages)

---

## 2. User & Role Matrix

| Role   | Primary Need |
|--------|--------------|
| Admin  | Manage users |
| User   | Upload songs, create worship sets, view chord charts, add musical notes (capo, key changes) |

### Permission Matrix

| Feature                      | Admin                       | User                      |
|-----------------------------|-----------------------------|---------------------------|
| Authentication              | Email/Google Sign-in        | Same                      |
| Role Assignment             | Can promote others to Admin | Auto-select at signup     |
| Upload PDF                  | ✅                          | ✅                         |
| Create Song (manual entry)  | ✅                          | ✅                         |
| Delete Song                 | ✅ (Permanent)              | ✅ (Soft delete)           |
| Flag "Needs Lyrics Order"   | ✅                          | ✅                         |
| Set Lyrics Order            | ✅                          | ✅                         |
| View Telugu Lyrics          | ✅                          | ✅                         |
| View English Transliteration| ✅                          | ✅                         |
| View Chord Charts           | ✅                          | ✅ (toggle on/off)         |
| View Personal Notes         | ✅                          | ✅                         |
| Create Set                  | ✅                          | ✅                         |
| Edit Set                    | ✅                          | ✅                         |
| Export Set as PDF           | Chords+Lyrics               | Chords+Lyrics             |
| User Management             | ✅                          | ❌                         |
| View Audit Logs             | ✅                          | ❌                         |
| Resolve Edit Conflicts      | ✅ (Can force)              | ❌                         |
| System Statistics           | ✅                          | ❌                         |

---

## 3. Complete Feature Specification

### 3.1 Core Content Management

- **Song Structure**
  - Bilingual: Telugu (UTF-8), Romanized (ISO 15919)
  - Blocks: Verse, Chorus, Bridge, Pre-Chorus, Outro (user-definable)
  - Metadata: Key, Tempo (BPM), Time signature, Tags
- **YouTube Integration**
  - Store YouTube link per song
  - In-app video player (iframe/embed)
- **Lyrics Order Flagging**
  - States: Needs Review → In Progress → Verified
- **PDF Management**
  - Dual PDF Types:
    1. Source PDF (uploaded chord sheet)
    2. Generated PDFs (with or without chords)
  - Upload Flow:
    1. User selects PDF
    2. OCR text extraction for search indexing
    3. Auto-detect chords and split into lyrics + chords
    4. Build structured JSON
    5. Store JSON in Firebase Storage
  - Example JSON structure:
    ```json
    {
      "song_title": "",
      "key": "",
      "structure": [
        {
          "type": "verse",
          "content": [
            {
              "telugu": "hello hello",
              "english": "Hello hello",
              "chords": "Em      C"
            }
          ]
        }
      ]
    }
    ```

---

### 3.2 Search & Discovery

- Multi-script search (Telugu, English transliteration, or mixed)
- Fuzzy matching (Algolia)
- Phonetic equivalence (example: sha variants)
- Filtering: Tags (user-defined), Key, Tempo, Recently added, Usage stats

---

### 3.3 Worship Set Management

- Set builder (drag-and-drop)
- Key transposition
- Notes per song (example: "Start with chorus")

---

### 3.4 Collaboration Features

- Personal notes (private/public)
- Note types: Text, Highlights

---

### 3.5 Administrative Features

- User management dashboard
- Role promotion (custom claims)
- Activity monitoring
- Content moderation (soft delete, bulk import via JSON/CSV)
- Analytics (song frequency, engagement, storage usage)

---

## 4. Security Model

- Firestore rules:
  - Read: Any authenticated user
  - Write:
    - Create: Any authenticated user
    - Update/Delete: Admin or User (soft delete)
- Role implementation: Firebase Auth auto-assigns User role

---

## 5. User Flows

### Flow 1: First-Time Setup
1. Install app
2. Google Sign-in
3. Auto-assign role
4. Tutorial walkthrough (Search, Create Set, Toggle Chords)

### Flow 2: Adding a New Song
1. Tap "+" → New Song
2. Manual entry OR PDF upload with OCR
3. Add YouTube link
4. Flag lyrics order status
5. Save → Algolia index update

### Flow 3: Sunday Morning Usage
0. All users get a notification if the next week's set is not finalized by mid-week
1. Leader creates set
2. Sync to all devices
3. Musicians add notes
4. Song usage is incremented automatically

---

## 6. Success Metrics

- App launch <2s
- Song search <500ms

---

## 7. Implementation Steps (Checklist)

1. **Project Setup**
   - [ ] Flutter project with Firebase integration
   - [ ] Set up Firestore, Storage, Auth
2. **Authentication & Roles**
   - [ ] Google sign-in
   - [ ] Role assignment logic
   - [ ] Admin dashboard
3. **Song Management**
   - [ ] Song data model (bilingual, chords, metadata)
   - [ ] PDF upload & OCR
   - [ ] Chord/lyric extraction & JSON conversion
   - [ ] YouTube link support
   - [ ] Lyrics order flagging
4. **Search & Discovery**
   - [ ] Algolia integration
   - [ ] Multi-script/phonetic search
   - [ ] Filtering UI
5. **Worship Set Management**
   - [ ] Set builder UI
   - [ ] Key transposition
   - [ ] Notes per song
6. **Collaboration & Notes**
   - [ ] Personal/public notes
   - [ ] Note types
7. **Admin & Analytics**
   - [ ] User management
   - [ ] Content moderation
   - [ ] Analytics dashboard
8. **Security**
   - [ ] Firestore rules
   - [ ] Audit logs
9. **Testing & Metrics**
   - [ ] Performance testing (launch/search)
   - [ ] Usage tracking
10. **PWA & Cross-Platform**
    - [ ] PWA support
    - [ ] Android/iOS/web builds

---

> Use this file as a step-by-step implementation guide. Check off items as you complete them. Update with new features or changes as needed.
