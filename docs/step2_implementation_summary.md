# Step 2: Importer Adapters (Read Portal, Write to Staging) - Implementation Summary

## 🎯 **Current Status: READY FOR TESTING**

Your Step 2 implementation is now complete and ready for testing! Here's what has been implemented:

### **Recent Updates (Latest):**
- ✅ **Refactored to use `PORTAL_VIEWS` hash** - Centralized portal view configuration
- ✅ **Updated `StagingSource` model** - Now uses `staging_sources` table (Rails convention)
- ✅ **Replaced raw SQL with ActiveRecord** - `create_source` now uses `StagingSource.create!`
- ✅ **Centralized configuration** - All table names managed in `StagingConfig`

## ✅ **What's Been Implemented:**

### **1. Core Infrastructure:**
- ✅ **Staging Table Management** - Creates, drops, and manages `*_new` tables
- ✅ **Dummy Data Generation** - Creates test data in `portal_standard_*` tables
- ✅ **Configuration Management** - Centralized settings for table names, batch sizes, etc.
- ✅ **Rake Task System** - Complete testing workflow

### **2. Import Pipeline:**
- ✅ **Main Portal Importer** (`Wdpa::Portal::Importer`) - Orchestrates the entire import
- ✅ **Attribute Importer** - Handles protected area attributes
- ✅ **Geometry Importer** - Handles PostGIS geometries
- ✅ **Source Importer** - Handles source metadata
- ✅ **Related Source Importer** - Handles PARCC and Irreplaceability data

### **3. Data Flow:**
- ✅ **Portal Data Reading** - Queries `portal_standard_polygons`, `portal_standard_points`, `portal_standard_sources`
- ✅ **Staging Table Writing** - Writes to `protected_areas_new`, `sources_staging`, `protected_area_parcels_new`
- ✅ **Batch Processing** - Configurable batch size (default: 1,000 records)
- ✅ **Metadata Relationships** - Links protected areas to sources via `metadataid`

## 🚀 **How to Test Your Implementation:**

### **Prerequisites:**
- Rails environment is running
- Database is accessible
- All gems are installed

### **1. Set Up Test Environment:**
```bash
# Enable test mode
export WDPA_PORTAL_TEST_MODE=true

# Optional: Customize data volume
export WDPA_PORTAL_DUMMY_COUNT=5000
export WDPA_PORTAL_BULK_BATCH_SIZE=1000
```

### **2. Run Complete Test:**
```bash
# This will: create staging tables, generate dummy data, run importer, show results
rake pp:portal:test_importer
```

### **3. Individual Steps (if needed):**
```bash
# Create staging tables
rake pp:portal:create_staging

# Generate dummy data
rake pp:portal:generate_dummy_views

# Check status
rake pp:portal:status

# Clean up
rake pp:portal:cleanup_dummy_views
rake pp:portal:drop_staging
```

## 📊 **Expected Test Results:**

### **Dummy Data Generated:**
- **`portal_standard_polygons`**: 5,000 polygon records
- **`portal_standard_points`**: 5,000 point records  
- **`portal_standard_sources`**: 10,000 source records

### **After Import:**
- **`protected_areas_new`**: ~10,000 records (polygons + points)
- **`staging_sources`**: ~10,000 records
- **`protected_area_parcels_new`**: Geometry data

### **Performance:**
- **Batch Size**: 1,000 records per batch
- **Total Batches**: ~15 batches (15,000 ÷ 1,000)
- **Memory Usage**: Optimized for large datasets

## 🔧 **Key Implementation Details:**

### **1. Column Mapping:**
```ruby
# Maps portal schema to ProtectedPlanet schema
PORTAL_TO_PP_MAPPING = {
  'wdpaid' => 'wdpaid',
  'name' => 'name',
  'wkb_geometry' => 'wkb_geometry',
  'metadataid' => 'metadataid',
  # ... all other fields
}
```

### **2. Batch Processing:**
```ruby
# Configurable batch size
BULK_BATCH_SIZE = (ENV['WDPA_PORTAL_BULK_BATCH_SIZE'] || 1000).to_i

# Processes records in manageable chunks
relation.find_in_batches(batch_size: batch_size) do |batch|
  # Process batch
end
```

### **3. Error Handling:**
- ✅ **Comprehensive error logging**
- ✅ **Batch-level error handling**
- ✅ **Graceful degradation** for missing data

## 🎯 **What This Tests:**

### **1. Data Reading:**
- ✅ **Portal data access** - Can read from `portal_standard_*` tables
- ✅ **Schema compatibility** - Column mappings work correctly
- ✅ **Data relationships** - `metadataid` linking works

### **2. Data Writing:**
- ✅ **Staging table insertion** - Can write to `*_new` tables
- ✅ **Geometry handling** - PostGIS data imports correctly
- ✅ **Batch performance** - Large datasets process efficiently

### **3. Import Pipeline:**
- ✅ **End-to-end workflow** - Complete import process
- ✅ **Error handling** - Robust error management
- ✅ **Performance** - Handles 10,000+ records

## 🔮 **Next Steps After Testing:**

## 📋 **Complete Command Reference for Step 1 & Step 2:**

### **Step 1: Source Shaping (Materialized Views + Mapping)**
*Note: This step will be implemented by another developer*

```bash
# 1. Create materialized views in Portal database
# This will create the portal_standard_* views that Step 2 reads from

# 2. Verify views exist and are accessible
# Check that portal_standard_polygons, portal_standard_points, portal_standard_sources exist

# 3. Validate data schema
# Ensure column names and types match Step 2 expectations
```

### **Step 2: Importer Adapters (Read Portal, Write to Staging)**
*Your current implementation - ready for testing*

```bash
# Environment Setup
export WDPA_PORTAL_TEST_MODE=true
export WDPA_PORTAL_DUMMY_COUNT=5000
export WDPA_PORTAL_BULK_BATCH_SIZE=1000

# Complete Test Workflow
rake pp:portal:test_importer

# Individual Components
rake pp:portal:create_staging          # Create staging tables
rake pp:portal:generate_dummy_views    # Generate test data
rake pp:portal:status                  # Check system status
rake pp:portal:cleanup_dummy_views    # Clean up test data
rake pp:portal:drop_staging           # Remove staging tables

# Force Cleanup (if needed)
rake pp:portal:force_cleanup          # Emergency cleanup
```

### **Step 2 Testing Commands (Detailed):**

```bash
# 1. Initial Setup
rake pp:portal:create_staging

# 2. Generate Test Data
rake pp:portal:generate_dummy_views

# 3. Run Import Test
rake pp:portal:test_importer

# 4. Verify Results
rake pp:portal:status

# 5. Cleanup
rake pp:portal:cleanup_dummy_views
rake pp:portal:drop_staging
```

### **Step 2 Debugging Commands:**

```bash
# Check staging table existence
rake pp:portal:status

# View specific table contents (in Rails console)
rails console
> StagingSource.count
> ProtectedAreaStaging.count
> ProtectedAreaParcelStaging.count

# Check dummy data generation
rails console
> ActiveRecord::Base.connection.table_exists?('portal_standard_polygons')
> ActiveRecord::Base.connection.table_exists?('portal_standard_points')
> ActiveRecord::Base.connection.table_exists?('portal_standard_sources')
```

### **Step 2 Environment Variables:**

```bash
# Required for testing
export WDPA_PORTAL_TEST_MODE=true

# Optional customization
export WDPA_PORTAL_DUMMY_COUNT=1000      # Default: 5000
export WDPA_PORTAL_BULK_BATCH_SIZE=500   # Default: 1000

# Disable test mode (for production)
unset WDPA_PORTAL_TEST_MODE
```

### **Step 2 Expected Output:**

```bash
# Successful test run should show:
✅ Staging tables created: protected_areas_new, protected_area_parcels_new, staging_sources
✅ Dummy portal tables created successfully!
✅ Portal import completed successfully
✅ Import Summary:
   - Protected Areas: 10000 records
   - Sources: 10000 records
   - Parcels: 10000 records
```

### **1. If Tests Pass:**
- ✅ **Step 2 is complete** and working
- ✅ **Ready for Step 3** (Release Orchestrator)
- ✅ **Can handle real data** once Step 1 is ready

### **2. If Issues Found:**
- 🔧 **Debug specific problems** in the import pipeline
- 🔧 **Adjust column mappings** if schema differs
- 🔧 **Optimize performance** if needed

## 📝 **TODO_IMPORT Tags (for Step 1 Integration):**

- **Column Mappings** - Verify against actual Step 1 schema
- **View Names** - Confirm `portal_standard_*` table names
- **Schema Validation** - Add validation against Step 1 views
- **Performance Tuning** - Optimize for production data volumes

---

## 🏆 **Congratulations!**

Your Step 2 implementation is **feature-complete** and ready for thorough testing. This represents a significant milestone in your portal migration project!

**Next**: Test with `rake pp:portal:test_importer` and then move to Step 3: Release Orchestrator.
