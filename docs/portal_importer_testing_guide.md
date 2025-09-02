# TO_BE_DELETED_STEP_1: This entire file should be deleted once Step 1 materialized views are ready
# This guide explains how to test the Portal Importer with dummy data for development purposes only
# Once Step 1 is complete, the real materialized views will be available and this file can be removed

# Portal Importer Testing Guide

## Overview

This guide explains how to test the Portal Importer **without** Step 1 being complete. The system now includes a test mode that generates dummy materialized views with sample data, allowing you to test the entire import pipeline.

## Test Mode Features

### ✅ **What Test Mode Provides**
- **Dummy Materialized Views**: Creates `portal_standard_polygons`, `portal_standard_points`, and `portal_standard_sources` views
- **Sample Data**: Generates realistic test data with proper schemas
- **Automatic Cleanup**: Removes dummy views after testing
- **Full Pipeline Testing**: Tests the complete import process from views to staging tables

### 🔧 **Test Mode Configuration**
- **Environment Variable**: `WDPA_PORTAL_TEST_MODE=true`
- **Customizable Data Count**: `WDPA_PORTAL_DUMMY_COUNT=50` (default: 100)
- **Automatic Detection**: System automatically detects and enables test mode

## Quick Start

### 1. **Enable Test Mode**
```bash
export WDPA_PORTAL_TEST_MODE=true
export WDPA_PORTAL_DUMMY_COUNT=50  # Optional: customize data count
```

### 2. **Run Test Import**
```bash
rake pp:portal:test_import_dummy
```

### 3. **Check Results**
```bash
rake pp:portal:status
```

## Available Test Commands

### **Rake Tasks**
```bash
# Test with dummy data (recommended)
rake pp:portal:test_import_dummy

# Generate dummy views only
rake pp:portal:generate_dummy_views

# Clean up dummy views
rake pp:portal:cleanup_dummy_views

# Check test configuration
rake pp:portal:test_config

# Check staging table status
rake pp:portal:status
```

### **Direct Script Execution**
```bash
# Run the complete test script
rails runner lib/modules/wdpa/portal/test_with_dummy_data.rb

# Or with environment variables
WDPA_PORTAL_TEST_MODE=true rails runner lib/modules/wdpa/portal/test_with_dummy_data.rb
```

## Test Mode Workflow

### **What Happens in Test Mode**

1. **Environment Check**: System detects `WDPA_PORTAL_TEST_MODE=true`
2. **Dummy View Generation**: Creates temporary materialized views with sample data
3. **Import Execution**: Runs the full portal import process
4. **Data Validation**: Imports data from dummy views to staging tables
5. **Automatic Cleanup**: Removes dummy views and resets environment

### **Sample Data Generated**

#### **Protected Areas (Polygons)**
- **Count**: 100 records (or custom count)
- **Sample Data**: Test Protected Area 1, Test Protected Area 2, etc.
- **Geometry**: Simple polygons for testing
- **Attributes**: Realistic WDPA field values

#### **Protected Areas (Points)**
- **Count**: 100 records (or custom count)
- **Sample Data**: Test Point Area 101, Test Point Area 102, etc.
- **Geometry**: Point geometries for testing
- **Attributes**: Different attribute values from polygons

#### **Sources**
- **Count**: 200 records (total of polygons + points)
- **Sample Data**: Test Source 1, Test Source 2, etc.
- **Attributes**: Source names, descriptions, URLs, types, years

## Testing Scenarios

### **1. Basic Import Testing**
```bash
# Test the complete import process
rake pp:portal:test_import_dummy
```

### **2. Staging Table Management**
```bash
# Create staging tables
rake pp:portal:create_staging

# Check status
rake pp:portal:status

# Clean up
rake pp:portal:drop_staging
```

### **3. Custom Data Volume Testing**
```bash
# Test with 50 records (faster)
export WDPA_PORTAL_DUMMY_COUNT=50
rake pp:portal:test_import_dummy

# Test with 1000 records (performance testing)
export WDPA_PORTAL_DUMMY_COUNT=1000
rake pp:portal:test_import_dummy
```

### **4. Step-by-Step Testing**
```bash
# Generate dummy views
rake pp:portal:generate_dummy_views

# Check that views exist
rake pp:portal:test_config

# Run import manually
rails runner "Wdpa::Portal::Importer.import"

# Clean up
rake pp:portal:cleanup_dummy_views
```

## Environment Variables

### **Required**
```bash
export WDPA_PORTAL_TEST_MODE=true
```

### **Optional**
```bash
export WDPA_PORTAL_DUMMY_COUNT=50      # Default: 100
export WDPA_PORTAL_DUMMY_COUNT=1000    # For performance testing
export WDPA_PORTAL_DUMMY_COUNT=10      # For quick testing
```

## Troubleshooting

### **Common Issues**

#### **1. "Required materialized views do not exist"**
```bash
# Solution: Enable test mode
export WDPA_PORTAL_TEST_MODE=true
rake pp:portal:test_import_dummy
```

#### **2. "Permission denied" for view creation**
```bash
# Solution: Check database permissions
# Ensure your database user can CREATE VIEW
```

#### **3. "Geometry functions not available"**
```bash
# Solution: Ensure PostGIS is installed and enabled
# Check: SELECT PostGIS_Version();
```

#### **4. Test mode not working**
```bash
# Check configuration
rake pp:portal:test_config

# Verify environment variable is set
echo $WDPA_PORTAL_TEST_MODE
```

### **Debug Mode**
```bash
# Enable verbose logging
export RAILS_LOG_LEVEL=debug

# Run test with detailed output
rake pp:portal:test_import_dummy
```

## Performance Testing

### **Data Volume Testing**
```bash
# Test with different data volumes
export WDPA_PORTAL_DUMMY_COUNT=100     # Small test
export WDPA_PORTAL_DUMMY_COUNT=1000    # Medium test
export WDPA_PORTAL_DUMMY_COUNT=10000   # Large test

rake pp:portal:test_import_dummy
```

### **Memory Usage Monitoring**
```bash
# Monitor memory during import
/usr/bin/time -v rake pp:portal:test_import_dummy
```

## Integration with Step 1

### **When Step 1 is Ready**

1. **Remove Test Mode**: Set `WDPA_PORTAL_TEST_MODE=false` or unset the variable
2. **Update Configuration**: Modify view names in `staging_config.rb` if needed
3. **Update Column Mappings**: Modify `column_mapper.rb` if schemas differ
4. **Test with Real Data**: Run `rake pp:portal:test_import` (without dummy data)

### **Transition Checklist**
- [ ] Step 1 materialized views are created
- [ ] View names match expected configuration
- [ ] Column schemas match expected mappings
- [ ] Test mode disabled (`WDPA_PORTAL_TEST_MODE=false`)
- [ ] Real import tested successfully

## Best Practices

### **Development Workflow**
1. **Always use test mode** when Step 1 is not ready
2. **Test with realistic data volumes** (100+ records)
3. **Clean up after testing** to avoid database clutter
4. **Monitor logs** for any import issues

### **Testing Strategy**
1. **Start small**: Test with 10-50 records first
2. **Scale up**: Increase to 1000+ records for performance testing
3. **Edge cases**: Test with various data types and geometries
4. **Error handling**: Verify graceful failure and cleanup

### **Environment Management**
1. **Use environment variables** for configuration
2. **Reset environment** after testing
3. **Document custom settings** for team members
4. **Version control** test configurations

## Summary

The Portal Importer now includes a comprehensive test mode that allows you to:

- ✅ **Test the complete import pipeline** without Step 1
- ✅ **Generate realistic dummy data** for thorough testing
- ✅ **Validate staging table operations** with sample data
- ✅ **Test performance** with configurable data volumes
- ✅ **Automatically clean up** test artifacts

This enables you to develop and test Step 2 independently while waiting for Step 1 to be completed by the other developer.
