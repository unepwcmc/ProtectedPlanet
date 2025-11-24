# Banner System Documentation

## Overview

The banner system allows you to display site-wide banners at the top of each page that can be managed through ComfyCMS admin interface. Banners can be closed by users and their state is remembered via cookies.

## Features

- **Site-wide display**: Banners appear on all pages
- **Cookie-based persistence**: Once closed, banners stay hidden until a new banner is created
- **Rich text content**: Banners use ComfyCMS rich text editor for content formatting
- **Optional titles**: Banner titles are optional for more flexible design
- **Admin management**: Full CRUD interface in ComfyCMS admin
- **Active/inactive states**: Control banner visibility

## Admin Interface

Access the banner management at `/admin/banners` in the ComfyCMS admin interface.

### Banner Fields

- **Title**: Banner title (optional, max 100 characters)
- **Content**: Rich text content for the banner body (uses ComfyCMS rich text editor)
- **Active**: Whether the banner is currently displayed

### Banner Management

1. **Create**: Click "New Banner" to create a new banner
2. **Edit**: Click "Edit" on any banner to modify it
3. **Delete**: Click "Delete" to remove a banner
4. **Activate/Deactivate**: Toggle the "Active" checkbox to show/hide banners

## Technical Implementation

### Models

- `Banner`: Main model storing banner data
- `current_banner`: Helper method to get the active banner
- `banner_visible?`: Helper method to check if banner should be displayed

### Views

- `app/views/layouts/partials/_banner.html.erb`: Banner display template
- Admin views in `app/views/admin/banners/`

### JavaScript

- `app/javascript/components/banner/Banner.vue`: Vue component handling banner display and navigation
- Handles single and multiple banner scenarios
- Sets appropriate cookies (single banner ID or signature for multiple)
- Provides smooth close animation and left/right navigation

### CSS

- `app/assets/stylesheets/banner.scss`: Banner styling
- Responsive design
- Multiple color variants

## Usage Examples

### Creating a Simple Banner

1. Go to `/admin/banners`
2. Click "New Banner"
3. Fill in:
   - Title: "Site Maintenance" (optional)
   - Content: Use the rich text editor to format: "We will be performing maintenance on Sunday at 2 AM."
   - Active: ✓
4. Click "Create Banner"

### Creating an Info Banner with Link

1. Go to `/admin/banners`
2. Click "New Banner"
3. Fill in:
   - Title: "New Feature Available" (optional)
   - Content: Use the rich text editor to format: "Check out our new interactive map!"
   - Active: ✓
4. Click "Create Banner"

### Creating a Banner Without Title

1. Go to `/admin/banners`
2. Click "New Banner"
3. Fill in:
   - Title: Leave blank
   - Content: Use the rich text editor to format your message
   - Active: ✓
4. Click "Create Banner"

## Cookie Behavior

- When a user closes a banner, a cookie is set with the banner ID
- The cookie expires after 1 year
- If a new banner is created, it will be shown even if the user previously closed a different banner
- The cookie is named `banner_closed` and contains the banner ID

## Customization


### Modifying Banner Display

Edit `app/views/layouts/partials/_banner.html.erb` to change the banner structure.

### JavaScript Customization

Modify `app/javascript/components/banner/Banner.vue` to change close behavior or add new functionality. The component follows Vue.js patterns and can be extended with additional features like auto-rotation, keyboard navigation, etc.

## Database Schema

```sql
CREATE TABLE banners (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255),
  content TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

## Migration

To set up the banner system:

1. Run the migration: `rails db:migrate`
2. Seed sample data: `rails db:seed`
3. Access admin at `/admin/banners`

## Troubleshooting

### Banner Not Showing

1. Check if a banner exists and is active
2. Verify the banner is not closed via cookie
3. Check browser console for JavaScript errors

### Admin Access Issues

1. Ensure you're logged into ComfyCMS admin
2. Check that routes are properly configured
3. Verify controller permissions

### Styling Issues

1. Check that `banner.scss` is imported in `application.scss`
2. Verify CSS classes are correctly applied
3. Check for CSS conflicts
