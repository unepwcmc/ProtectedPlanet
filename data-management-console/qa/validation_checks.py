import datetime
import re
import time
import numpy as np
import pandas as pd

from postgres.postgresconnection import PostgresConnection
from postgres.postgresexecutor import PostgresExecutor

def to_array_of_dict(nparray, field_list):
    return [dict(zip(field_list, list(row))) for row in nparray]

def arcgis_table_to_df(metadata_id):
    sql = f'SELECT *, ST_GeometryType(shape) as shapetype FROM wdpa_wdoecm_subset WHERE METADATAID={metadata_id}'
    connection = PostgresConnection.get_connection()
    df = pd.read_sql_query(sql, connection)
    df = df.set_index('id', drop=True)  # set OBJECTID as index, but no longer use it as column
    df.replace('', np.nan, inplace=True)  # set '' to np.nan
    return df

def polygons_only(data_frame):
    polygon_types = ['POLYGON', 'MULTIPOLYGON']
    df = data_frame[data_frame['shapetype'].isin(polygon_types)]
    return df

def get_iso3():
    sql = "SELECT DISTINCT CODE FROM iso3 WHERE ToZ='9999-01-01'"
    cursor = PostgresExecutor.get_cursor()
    cursor.execute(sql)
    iso3 = [ row[0] for row in cursor.fetchall()]
    return iso3


#############################################################################
# 2.0. Utility to extract rows from the WDPA, based on WDPA_PID input ####
#############################################################################

def find_wdpa_rows(wdpa_df, wdpa_pid):
    """
    Return a subset of DataFrame based on wdpa_pid list
    ## Arguments ##
    wdpa_df --  wdpa DataFrame
    wdpa_pid -- a list of WDPA_PIDs
    """

    return wdpa_df[wdpa_df['wdpa_pid'].isin(wdpa_pid)]


#######################################
# 2.1. Find duplicate WDPA_PIDs ####
#######################################

def duplicate_wdpa_pid(wdpa_df, return_pid=False):
    """
    Return True if WDPA_PID is duplicate in the DataFrame.
    Return list of WDPA_PID, if duplicates are present
    and return_pid is set True.
    """

    if return_pid:
        ids = wdpa_df['wdpa_pid']  # make a variable of the field to find
        return to_array_of_dict(ids[ids.duplicated()].unique(), ['wdpa_pid'])  # return duplicate WDPA_PIDs

    return wdpa_df['wdpa_pid'].nunique() != wdpa_df.index.size  # this returns True if there are WDPA_PID duplicates


###########################################################################
# 2.2. Invalid: MARINE designation based on GIS_AREA and GIS_M_AREA ####
###########################################################################

def area_invalid_marine(wdpa_df, return_pid=False):
    """
    Assign a new 'MARINE' value based on GIS calculations, called marine_GIS_value
    Return True if marine_GIS_value is unequal to MARINE
    Return list of WDPA_PIDs where MARINE is invalid, if return_pid is set True
    """

    # set min and max for 'coastal' designation (MARINE = 1)
    coast_min = 0.1
    coast_max = 0.9

    # create new column with proportion marine vs total GIS area
    wdpa_df['marine_GIS_proportion'] = wdpa_df['gis_m_area'] / wdpa_df['gis_area']

    def assign_marine_gis_value(df):
        if df['marine_GIS_proportion'] <= coast_min:
            return '0'
        elif coast_min < df['marine_GIS_proportion'] < coast_max:
            return '1'
        elif df['marine_GIS_proportion'] >= coast_max:
            return '2'

    # calculate the marine_value
    wdpa_df['marine_GIS_value'] = wdpa_df.apply(assign_marine_gis_value, axis=1)

    return_fields = ['wdpa_pid', 'marine_GIS_value', 'marine']
    # find invalid WDPA_PIDs
    invalid_wdpa_pid = wdpa_df[wdpa_df['marine_GIS_value'] != wdpa_df['marine']][return_fields].values

    if return_pid:
        return to_array_of_dict(invalid_wdpa_pid, return_fields)

    return len(invalid_wdpa_pid) > 0


############################################
# 2.3. Invalid: GIS_AREA >> REP_AREA ####
############################################

def area_invalid_too_large_gis(wdpa_df, return_pid=False):
    """
    Return True if GIS_AREA is too large compared to REP_AREA - based on thresholds specified below.
    Return list of WDPA_PIDs where GIS_AREA is too large compared to REP_AREA, if return_pid=True
    """

    # Set maximum allowed absolute difference between GIS_AREA and REP_AREA (in km²)
    MAX_ALLOWED_SIZE_DIFF_KM2 = 50

    # Create two Series:
    # One to calculate the mean and stdev without outliers
    # One to use as index, to find WDPA_PIDs with a too large GIS_AREA

    # Compare GIS_AREA to REP_AREA, replace outliers with NaN, then obtain mean and stdev
    # Settings
    calc = (wdpa_df['rep_area'] + wdpa_df['gis_area']) / wdpa_df['rep_area']
    condition = [calc > 100,
                 calc < 0]
    choice = [np.nan, np.nan]

    # Produce column without outliers
    relative_size_stats = pd.Series(
        np.select(condition, choice, default=calc))

    # Calculate the maximum allowed values for relative_size using mean and stdev
    max_gis = relative_size_stats.mean() + (2 * relative_size_stats.std())

    # Series: compare REP_AREA to GIS_AREA
    relative_size = pd.Series((wdpa_df['rep_area'] + wdpa_df['gis_area']) / wdpa_df['rep_area'])

    # Find the rows with an incorrect GIS_AREA
    return_fields = ['wdpa_pid', 'gis_area', 'rep_area']
    invalid_wdpa_pid = \
        wdpa_df[
            (relative_size > max_gis) & (abs(wdpa_df['gis_area'] - wdpa_df['rep_area']) > MAX_ALLOWED_SIZE_DIFF_KM2)][
            return_fields].values

    if return_pid:
        return to_array_of_dict(invalid_wdpa_pid, return_fields)

    return len(invalid_wdpa_pid) > 0


############################################
# 2.4. Invalid: REP_AREA >> GIS_AREA ####
############################################

def area_invalid_too_large_rep(wdpa_df, return_pid=False):
    """
    Return True if REP_AREA is too large compared to GIS_AREA - based on thresholds specified below.
    Return list of WDPA_PIDs where REP_AREA is too large compared to GIS_AREA, if return_pid=True
    """

    # Set maximum allowed absolute difference between GIS_AREA and REP_AREA (in km²)
    MAX_ALLOWED_SIZE_DIFF_KM2 = 50

    # Create two Series:
    # One to calculate the mean and stdev without outliers
    # One to use as index, to find WDPA_PIDs with a too large REP_AREA

    # Compare GIS_AREA to REP_AREA, replace outliers with NaN, then obtain mean and stdev
    # Settings
    calc = (wdpa_df['rep_area'] + wdpa_df['gis_area']) / wdpa_df['gis_area']
    condition = [calc > 100,
                 calc < 0]
    choice = [np.nan, np.nan]

    # Produce Series without outliers
    relative_size_stats = pd.Series(
        np.select(condition, choice, default=calc))

    # Calculate the maximum and minimum allowed values for relative_size using mean and stdev
    max_rep = relative_size_stats.mean() + (2 * relative_size_stats.std())

    # Series: compare REP_AREA to GIS_AREA
    relative_size = pd.Series((wdpa_df['rep_area'] + wdpa_df['gis_area']) / wdpa_df['gis_area'])

    # Find the rows with an incorrect REP_AREA
    return_fields = ['wdpa_pid', 'rep_area', 'gis_area']
    invalid_wdpa_pid = wdpa_df[
                        (relative_size > max_rep) & (abs(wdpa_df['rep_area'] - wdpa_df['gis_area']) > MAX_ALLOWED_SIZE_DIFF_KM2)][
                        return_fields].values

    if return_pid:
        return to_array_of_dict(invalid_wdpa_pid, return_fields)

    return len(invalid_wdpa_pid) > 0


################################################
# 2.5. Invalid: GIS_M_AREA >> REP_M_AREA ####
################################################

def area_invalid_too_large_gis_m(wdpa_df, return_pid=False):
    """
    Return True if GIS_M_AREA is too large compared to REP_M_AREA - based on thresholds specified below.
    Return list of WDPA_PIDs where GIS_M_AREA is too large compared to REP_M_AREA, if return_pid=True
    """

    # Set maximum allowed absolute difference between GIS_M_AREA and REP_M_AREA (in km²)
    MAX_ALLOWED_SIZE_DIFF_KM2 = 50

    # Create two Series:
    # One to calculate the mean and stdev without outliers
    # One to use as index, to find WDPA_PIDs with a too large GIS_M_AREA

    # Compare GIS_M_AREA to REP_M_AREA, replace outliers with NaN, then obtain mean and stdev
    # Settings
    calc = (wdpa_df['rep_m_area'] + wdpa_df['gis_m_area']) / wdpa_df['rep_m_area']
    condition = [calc > 100,
                 calc < 0]
    choice = [np.nan, np.nan]

    # Produce column without outliers
    relative_size_stats = pd.Series(
        np.select(condition, choice, default=calc))

    # Calculate the maximum and minimum allowed values for relative_size using mean and stdev
    max_gis = relative_size_stats.mean() + (2 * relative_size_stats.std())

    # Series: compare REP_M_AREA to GIS_M_AREA
    relative_size = pd.Series((wdpa_df['rep_m_area'] + wdpa_df['gis_m_area']) / wdpa_df['rep_m_area'])

    # Find the rows with an incorrect GIS_M_AREA
    return_fields = [ 'wdpa_pid', 'gis_m_area', 'rep_m_area']
    invalid_wdpa_pid = wdpa_df[
        (relative_size > max_gis) & (abs(wdpa_df['gis_m_area'] - wdpa_df['rep_m_area']) > MAX_ALLOWED_SIZE_DIFF_KM2)][
        return_fields].values

    if return_pid:
        return to_array_of_dict(invalid_wdpa_pid, return_fields)

    return len(invalid_wdpa_pid) > 0


################################################
# 2.6. Invalid: REP_M_AREA >> GIS_M_AREA ####
################################################

def area_invalid_too_large_rep_m(wdpa_df, return_pid=False):
    """
    Return True if REP_M_AREA is too large compared to GIS_M_AREA - based on thresholds specified below.
    Return list of WDPA_PIDs where REP_M_AREA is too large compared to GIS_M_AREA, if return_pid=True
    """

    # Set maximum allowed absolute difference between GIS_M_AREA and REP_M_AREA (in km²)
    MAX_ALLOWED_SIZE_DIFF_KM2 = 50

    # Create two Series:
    # One to calculate the mean and stdev without outliers
    # One to use as index, to find WDPA_PIDs with a too large REP_M_AREA

    # Compare GIS_M_AREA to REP_M_AREA, replace outliers with NaN, then obtain mean and stdev
    # Settings
    calc = (wdpa_df['rep_m_area'] + wdpa_df['gis_m_area']) / wdpa_df['gis_m_area']
    condition = [calc > 100,
                 calc < 0]
    choice = [np.nan, np.nan]

    # Produce column without outliers
    relative_size_stats = pd.Series(
        np.select(condition, choice, default=calc))

    # Calculate the maximum and minimum allowed values for relative_size using mean and stdev
    max_rep = relative_size_stats.mean() + (2 * relative_size_stats.std())

    # Series: compare REP_M_AREA to GIS_M_AREA
    relative_size = pd.Series((wdpa_df['rep_m_area'] + wdpa_df['gis_m_area']) / wdpa_df['gis_m_area'])

    # Find the rows with an incorrect REP_M_AREA
    return_fields = ['wdpa_pid','rep_m_area','gis_m_area']
    invalid_wdpa_pid = wdpa_df[
        (relative_size > max_rep) & (abs(wdpa_df['rep_m_area'] - wdpa_df['gis_m_area']) > MAX_ALLOWED_SIZE_DIFF_KM2)][
        return_fields].values

    if return_pid:
        return to_array_of_dict(invalid_wdpa_pid, return_fields)

    return len(invalid_wdpa_pid) > 0


#######################################################
# 2.7. Invalid: GIS_AREA <= 0.0001 km² (100 m²) ####
#######################################################

def area_invalid_gis_area(wdpa_df, return_pid=False):
    """
    Return True if GIS_AREA is smaller than 0.0001 km²
    Return list of WDPA_PIDs where GIS_AREA is smaller than 0.0001 km², if return_pid=True
    """

    # Arguments
    size_threshold = 0.0001
    field_gis_area = 'gis_area'

    # Find invalid WDPA_PIDs
    return_fields = ['wdpa_pid', field_gis_area]
    invalid_wdpa_pid = wdpa_df[wdpa_df[field_gis_area] <= size_threshold][return_fields].values

    if return_pid:
        return to_array_of_dict(invalid_wdpa_pid, return_fields)

    return len(invalid_wdpa_pid) > 0


#######################################################
# 2.8. Invalid: REP_AREA <= 0.0001 km² (100 m²) ####
#######################################################

def area_invalid_rep_area(wdpa_df, return_pid=False):
    """
    Return True if REP_AREA is smaller than 0.0001 km²
    Return list of WDPA_PIDs where REP_AREA is smaller than 0.0001 km², if return_pid=True
    """

    # Arguments
    size_threshold = 0.0001
    field_rep_area = 'rep_area'

    # Find invalid WDPA_PIDs
    return_fields = ['wdpa_pid', field_rep_area]
    invalid_wdpa_pid = wdpa_df[wdpa_df[field_rep_area] <= size_threshold][return_fields].values

    if return_pid:
        return to_array_of_dict(invalid_wdpa_pid, return_fields)

    return len(invalid_wdpa_pid) > 0


#################################################
# 2.8.a Invalid: REP_AREA >= 500,000 km²  ####
#################################################

def area_invalid_big_rep_area(wdpa_df, return_pid=False):
    """
    Return True if REP_AREA is larger than 500,000 km²
    Return list of WDPA_PIDs where REP_AREA is larger than 500,000 km², if return_pid=True
    """

    # Arguments
    size_threshold = 500000
    field_rep_area = 'rep_area'

    # Find invalid WDPA_PIDs
    return_fields = ['wdpa_pid', field_rep_area]
    invalid_wdpa_pid = wdpa_df[wdpa_df[field_rep_area] >= size_threshold][return_fields].values

    if return_pid:
        return to_array_of_dict(invalid_wdpa_pid, return_fields)

    return len(invalid_wdpa_pid) > 0


############################################################
# 2.9. Invalid: REP_M_AREA <= 0 when MARINE = 1 or 2 ####
############################################################

def area_invalid_rep_m_area_marine12(wdpa_df, return_pid=False):
    """
    Return True if REP_M_AREA is smaller than or equal to 0 while MARINE = 1 or 2
    Return list of WDPA_PIDs where REP_M_AREA is invalid, if return_pid=True
    """

    # Arguments
    field = 'rep_m_area'
    field_allowed_values = 0
    condition_field = 'marine'
    condition_crit = ['1', '2']

    # Find invalid WDPA_PIDs
    invalid_wdpa_pid = \
        wdpa_df[(wdpa_df[field] <= field_allowed_values) & (wdpa_df[condition_field].isin(condition_crit))][
            'wdpa_pid'].values

    if return_pid:
        return to_array_of_dict( wdpa_df[(wdpa_df[field] <= field_allowed_values) & (wdpa_df[condition_field].isin(condition_crit))][
                        ['wdpa_pid', field]].values,
                        [ 'wdpa_pid', field] )


    return len(invalid_wdpa_pid) > 0


##########################################################
# 2.10. Invalid: GIS_M_AREA <= 0 when MARINE = 1 or 2 ###
##########################################################

def area_invalid_gis_m_area_marine12(wdpa_df, return_pid=False):
    """
    Return True if GIS_M_AREA is smaller than or equal to 0 while MARINE = 1 or 2
    Return list of WDPA_PIDs where GIS_M_AREA is invalid, if return_pid=True
    """

    # Arguments
    field = 'gis_m_area'
    field_allowed_values = 0
    condition_field = 'marine'
    condition_crit = ['1', '2']

    # Find invalid WDPA_PIDs
    return_fields = ['wdpa_pid', field]
    invalid_wdpa_pid = \
        wdpa_df[(wdpa_df[field] <= field_allowed_values) & (wdpa_df[condition_field].isin(condition_crit))][
            return_fields].values

    if return_pid:
        return to_array_of_dict(invalid_wdpa_pid, return_fields)

    return len(invalid_wdpa_pid) > 0


########################################################
# 2.11. Invalid: NO_TAKE, NO_TK_AREA and REP_M_AREA ####
########################################################

def invalid_no_take_no_tk_area_rep_m_area(wdpa_df, return_pid=False):
    """
    Return True if NO_TAKE = 'All' while the REP_M_AREA is unequal to NO_TK_AREA
    Return list of WDPA_PIDs where NO_TAKE is invalid, if return_pid=True
    """

    # Select rows with NO_TAKE = 'All'
    no_take_all = wdpa_df[wdpa_df['no_take'] == 'all']

    # Select rows where the REP_M_AREA is unequal to NO_TK_AREA
    return_fields = ['wdpa_pid', 'rep_m_area']
    invalid_wdpa_pid = no_take_all[no_take_all['rep_m_area'] != no_take_all['no_tk_area']][return_fields].values

    if return_pid:
        return to_array_of_dict(invalid_wdpa_pid, return_fields)

    return len(invalid_wdpa_pid) > 0


############################################################################
# 2.12. Invalid: INT_CRIT & DESIG_ENG - non-Ramsar Site, non-WHS sites ####
############################################################################

def invalid_int_crit_desig_eng_other(wdpa_df, return_pid=False):
    """
    Return True if DESIG_ENG is something else than Ramsar Site (...)' or 'World Heritage Site (...)'
    while INT_CRIT is unequal to 'Not Applicable'. Other-than Ramsar / WHS should not contain anything
    else than 'Not Applicable'.
    Return list of WDPA_PIDs where INT_CRIT is invalid, if return_pid is set True
    """

    # Arguments
    field = 'desig_eng'
    field_allowed_values = ['Ramsar Site, Wetland of International Importance',
                            'World Heritage Site (natural or mixed)']
    condition_field = 'int_crit'
    condition_crit = ['Not Applicable']

    # Find invalid WDPA_PIDs
    return_fields=['wdpa_pid', field, condition_field]
    invalid_wdpa_pid = \
        wdpa_df[(~wdpa_df[field].isin(field_allowed_values)) & (~wdpa_df[condition_field].isin(condition_crit))][
            return_fields].values

    if return_pid:
        return to_array_of_dict(invalid_wdpa_pid, return_fields)

    return len(invalid_wdpa_pid) > 0


#########################################################################
# 2.13. Invalid: DESIG_ENG & IUCN_CAT - non-UNESCO, non-WHS sites ####
#########################################################################

def invalid_desig_eng_iucn_cat_other(wdpa_df, return_pid=False):
    """
    Return True if IUCN_CAT is unequal to the allowed values
    and DESIG_ENG is unequal to 'UNESCO-MAB (...)' or 'World Heritage Site (...)'
    Return list of WDPA_PIDs where IUCN_CAT is invalid, if return_pid is set True
    """

    # Arguments
    field = 'iucn_cat'
    field_allowed_values = ['Ia',
                            'Ib',
                            'II',
                            'III',
                            'IV',
                            'V',
                            'VI',
                            'Not Reported',
                            'Not Assigned']
    condition_field = 'desig_eng'
    condition_crit = ['UNESCO-MAB Biosphere Reserve',
                      'World Heritage Site (natural or mixed)']

    # Find invalid WDPA_PIDs
    return_fields=['wdpa_pid', field, condition_field]
    invalid_wdpa_pid = \
        wdpa_df[(~wdpa_df[field].isin(field_allowed_values)) & (~wdpa_df[condition_field].isin(condition_crit))][
            return_fields].values

    if return_pid:
        return to_array_of_dict(invalid_wdpa_pid, return_fields)

    return len(invalid_wdpa_pid) > 0

#########################################################
#### 3. Find inconsistent fields for the same WDPAID ####
#########################################################

#### Factory Function ####

def inconsistent_fields_same_wdpaid(wdpa_df,
                                        check_field,
                                        return_pid=False):
    '''
    Factory Function: this generic function is to be linked to
    the family of 'inconsistent' input functions stated below. These latter
    functions are to give information on which fields to check and pull
    from the DataFrame. This function is the foundation of the others.
    This function checks the WDPA for inconsistent values and
    returns a list of WDPA_PIDs that have invalid values for the specified field(s).
    Return True if inconsistent Fields are found for rows
    sharing the same WDPAID
    Return list of WDPA_PID where inconsistencies occur, if
    return_pid is set True
    ## Arguments ##
    check_field -- string of the field to check for inconsistency
    ## Example ##
    inconsistent_fields_same_wdpaid(
        wdpa_df=wdpa_df,
        check_field="DESIG_ENG",
        return_pid=True):
    '''

    if return_pid:
        # Group by WDPAID to find duplicate WDPAIDs and count the
        # number of unique values for the field in question
        wdpaid_groups = wdpa_df.groupby(['wdpaid'])[check_field].nunique()

        # Select all WDPAID duplicates groups with >1 unique value for
        # specified field ('check_attributtes') and use their index to
        # return the WDPA_PIDs
        return_fields = ['wdpa_pid', check_field]
        invalid_wdpa_ids = wdpa_df[wdpa_df['wdpaid'].isin(wdpaid_groups[wdpaid_groups > 1].index)][return_fields].values
        return to_array_of_dict(invalid_wdpa_ids, return_fields)

    # Sum the number of times a WDPAID has more than 1 value for a field
    return (wdpa_df.groupby('wdpaid')[check_field].nunique() > 1).sum() > 0

#### Input functions ####

#################################
#### 3.1. Inconsistent NAME #####
#################################

def inconsistent_name_same_wdpaid(wdpa_df, return_pid=False):
    '''
    This function is to capture inconsistencies in the field 'NAME'
    for records with the same WDPAID
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing field inconsistencies
    '''

    check_field = 'NAME'

    # The command below loads the factory function
    # and adds the check_field and return_pid arguments in it
    # to evaluate the wdpa_df for these arguments
    return inconsistent_fields_same_wdpaid(wdpa_df, check_field, return_pid)

#####################################
#### 3.2. Inconsistent ORIG_NAME ####
#####################################

def inconsistent_orig_name_same_wdpaid(wdpa_df, return_pid=False):
    '''
    This function is to capture inconsistencies in the field 'ORIG_NAME'
    for records with the same WDPAID
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing field inconsistencies
    '''

    check_field = 'orig_name'

    return inconsistent_fields_same_wdpaid(wdpa_df, check_field, return_pid)

#################################
#### 3.3. Inconsistent DESIG ####
#################################

def inconsistent_desig_same_wdpaid(wdpa_df, return_pid=False):
    '''
    This function is to capture inconsistencies in the field 'DESIG'
    for records with the same WDPAID
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing field inconsistencies
    '''

    check_field = 'desig'

    return inconsistent_fields_same_wdpaid(wdpa_df, check_field, return_pid)

#####################################
#### 3.4. Inconsistent DESIG_ENG ####
#####################################

def inconsistent_desig_eng_same_wdpaid(wdpa_df, return_pid=False):
    '''
    This function is to capture inconsistencies in the field 'DESIG_ENG'
    for records with the same WDPAID
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing field inconsistencies
    '''

    check_field = 'desig_eng'

    return inconsistent_fields_same_wdpaid(wdpa_df, check_field, return_pid)

######################################
#### 3.5. Inconsistent DESIG_TYPE ####
######################################

def inconsistent_desig_type_same_wdpaid(wdpa_df, return_pid=False):
    '''
    This function is to capture inconsistencies in the field 'DESIG_TYPE'
    for records with the same WDPAID
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing field inconsistencies
    '''

    check_field = 'desig_type'

    return inconsistent_fields_same_wdpaid(wdpa_df, check_field, return_pid)


####################################
#### 3.6. Inconsistent INT_CRIT ####
####################################

def inconsistent_int_crit_same_wdpaid(wdpa_df, return_pid=False):
    '''
    This function is to capture inconsistencies in the field 'INT_CRIT'
    for records with the same WDPAID
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing field inconsistencies
    '''

    check_field = 'int_crit'

    return inconsistent_fields_same_wdpaid(wdpa_df, check_field, return_pid)

###################################
#### 3.7. Inconsistent NO_TAKE ####
###################################

def inconsistent_no_take_same_wdpaid(wdpa_df, return_pid=False):
    '''
    This function is to capture inconsistencies in the field 'NO_TAKE'
    for records with the same WDPAID
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing field inconsistencies
    '''
    check_field = 'no_take'

    return inconsistent_fields_same_wdpaid(wdpa_df, check_field, return_pid)

##################################
#### 3.8. Inconsistent STATUS ####
##################################

def inconsistent_status_same_wdpaid(wdpa_df, return_pid=False):
    '''
    This function is to capture inconsistencies in the field 'STATUS'
    for records with the same WDPAID
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing field inconsistencies
    '''
    check_field = 'status'

    return inconsistent_fields_same_wdpaid(wdpa_df, check_field, return_pid)

#####################################
#### 3.9. Inconsistent STATUS_YR ####
#####################################

def inconsistent_status_yr_same_wdpaid(wdpa_df, return_pid=False):
    '''
    This function is to capture inconsistencies in the field 'STATUS_YR'
    for records with the same WDPAID
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing field inconsistencies
    '''
    check_field = 'status_yr'

    return inconsistent_fields_same_wdpaid(wdpa_df, check_field, return_pid)

#####################################
#### 3.10. Inconsistent GOV_TYPE ####
#####################################

def inconsistent_gov_type_same_wdpaid(wdpa_df, return_pid=False):
    '''
    This function is to capture inconsistencies in the field 'GOV_TYPE'
    for records with the same WDPAID
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing field inconsistencies
    '''
    check_field = 'gov_type'

    return inconsistent_fields_same_wdpaid(wdpa_df, check_field, return_pid)

#####################################
#### 3.11. Inconsistent OWN_TYPE ####
#####################################

def inconsistent_own_type_same_wdpaid(wdpa_df, return_pid=False):
    '''
    This function is to capture inconsistencies in the field 'OWN_TYPE'
    for records with the same WDPAID
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing field inconsistencies
    '''
    check_field = 'own_type'

    return inconsistent_fields_same_wdpaid(wdpa_df, check_field, return_pid)

######################################
#### 3.12. Inconsistent MANG_AUTH ####
######################################

def inconsistent_mang_auth_same_wdpaid(wdpa_df, return_pid=False):
    '''
    This function is to capture inconsistencies in the field 'MANG_AUTH'
    for records with the same WDPAID
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing field inconsistencies
    '''

    check_field = 'mang_auth'

    return inconsistent_fields_same_wdpaid(wdpa_df, check_field, return_pid)

######################################
#### 3.13. Inconsistent MANG_PLAN ####
######################################

def inconsistent_mang_plan_same_wdpaid(wdpa_df, return_pid=False):
    '''
    This function is to capture inconsistencies in the field 'MANG_PLAN'
    for records with the same WDPAID
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing field inconsistencies
    '''
    check_field = 'mang_plan'

    return inconsistent_fields_same_wdpaid(wdpa_df, check_field, return_pid)

##################################
#### 3.14. Inconsistent VERIF ####
##################################

def inconsistent_verif_same_wdpaid(wdpa_df, return_pid=False):
    '''
    This function is to capture inconsistencies in the field 'VERIF'
    for records with the same WDPAID
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing field inconsistencies
    '''
    check_field = 'verif'

    return inconsistent_fields_same_wdpaid(wdpa_df, check_field, return_pid)

#######################################
#### 3.15. Inconsistent METADATAID ####
#######################################

def inconsistent_metadataid_same_wdpaid(wdpa_df, return_pid=False):
    '''
    This function is to capture inconsistencies in the field 'METADATAID'
    for records with the same WDPAID
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing field inconsistencies
    '''
    check_field = 'metadataid'

    return inconsistent_fields_same_wdpaid(wdpa_df, check_field, return_pid)

####################################
#### 3.16. Inconsistent SUB_LOC ####
####################################

def inconsistent_sub_loc_same_wdpaid(wdpa_df, return_pid=False):
    '''
    This function is to capture inconsistencies in the field 'SUB_LOC'
    for records with the same WDPAID
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing field inconsistencies
    '''
    check_field = 'sub_loc'

    return inconsistent_fields_same_wdpaid(wdpa_df, check_field, return_pid)

#######################################
### 3.17. Inconsistent PARENT_ISO3 ####
#######################################

def inconsistent_parent_iso3_same_wdpaid(wdpa_df, return_pid=False):
    '''
    This function is to capture inconsistencies in the field 'PARENT_ISO3'
    for records with the same WDPAID
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing field inconsistencies
    '''
    check_field = 'parent_iso3'

    return inconsistent_fields_same_wdpaid(wdpa_df, check_field, return_pid)

#################################
#### 3.18. Inconsistent ISO3 ####
#################################


def inconsistent_iso3_same_wdpaid(wdpa_df, return_pid=False):
    '''
    This function is to capture inconsistencies in the field 'ISO3'
    for records with the same WDPAID
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing field inconsistencies
    '''
    check_field = 'iso3'

    return inconsistent_fields_same_wdpaid(wdpa_df, check_field, return_pid)

##########################################
#### 4. Find invalid values in fields ####
##########################################

#### Factory Function ####

def invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid=False):
    '''
    Factory Function: this generic function is to be linked to
    the family of 'invalid' input functions stated below. These latter
    functions are to give information on which fields to check and pull
    from the DataFrame. This function is the foundation of the others.
    This function checks the WDPA for invalid values and returns a list of WDPA_PIDs
    that have invalid values for the specified field(s).
    Return True if invalid values are found in specified fields.
    Return list of WDPA_PIDs with invalid fields, if return_pid is set True.
    ## Arguments ##
    field                -- a string specifying the field to be checked
    field_allowed_values -- a list of expected values in each field
    condition_field      -- a list with another field on which the evaluation of
                            invalid values depends; leave "" if no condition specified
    condition_crit       -- a list of values for which the condition_field
                            needs to be evaluated; leave [] if no condition specified
    ## Example ##
    invalid_value_in_field(
        wdpa_df,
        field="DESIG_ENG",
        field_allowed_values=["Ramsar Site, Wetland of International Importance",
                              "UNESCO-MAB Biosphere Reserve",
                              "World Heritage Site (natural or mixed)"],
        condition_field="DESIG_TYPE",
        condition_crit=["International"],
        return_pid=True):
    '''

    # if condition_field and condition_crit are specified
    # Modified - WEDS
    return_fields = ['wdpa_pid', field]
    if condition_field != '' and condition_crit != []:
        return_fields.append(condition_field)
        invalid_wdpa_pid = wdpa_df[(~wdpa_df[field].isin(field_allowed_values)) & (wdpa_df[condition_field].isin(condition_crit))][return_fields].values
        if return_pid:
            return to_array_of_dict(invalid_wdpa_pid, return_fields)
    else:
        invalid_wdpa_pid = wdpa_df[~wdpa_df[field].isin(field_allowed_values)][return_fields].values
        if return_pid:
            return to_array_of_dict(invalid_wdpa_pid, return_fields)

    return len(invalid_wdpa_pid) > 0

#### Input functions ####

#############################
#### 4.1. Invalid PA_DEF ####
#############################

def invalid_pa_def(wdpa_df, return_pid=False):
    '''
    Return True if PA_DEF not 1
    Return list of WDPA_PIDs where PA_DEF is not 1, if return_pid is set True
    '''

    field = 'pa_def'
    field_allowed_values = ['1'] # WDPA datatype is string
    condition_field = ''
    condition_crit = []

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)

################################################
#### 4.2. Invalid DESIG_ENG - international ####
################################################

def invalid_desig_eng_international(wdpa_df, return_pid=False):
    '''
    Return True if DESIG_ENG is invalid while DESIG_TYPE is 'International'
    Return list of WDPA_PIDs where DESIG_ENG is invalid, if return_pid is set True
    '''

    field = 'desig_eng'
    field_allowed_values = ['Ramsar Site, Wetland of International Importance',
                            'UNESCO-MAB Biosphere Reserve',
                            'World Heritage Site (natural or mixed)']
    condition_field = 'desig_type'
    condition_crit = ['International']

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)

#################################################
#### 4.3. Invalid DESIG_TYPE - international ####
#################################################

def invalid_desig_type_international(wdpa_df, return_pid=False):
    '''
    Return True if DESIG_TYPE is unequal to 'International', while DESIG_ENG is an allowed 'International' value
    Return list of WDPA_PIDs where DESIG_TYPE is invalid, if return_pid is set True
    '''

    field = 'desig_type'
    field_allowed_values = ['International']
    condition_field = 'desig_eng'
    condition_crit = ['Ramsar Site, Wetland of International Importance',
                      'UNESCO-MAB Biosphere Reserve',
                      'World Heritage Site (natural or mixed)']

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)


###########################################
#### 4.4. Invalid DESIG_ENG - regional ####
###########################################

def invalid_desig_eng_regional(wdpa_df, return_pid=False):
    '''
    Return True if DESIG_ENG is invalid while DESIG_TYPE is 'Regional'
    Return list of WDPA_PIDs where DESIG_ENG is invalid, if return_pid is set True
    '''

    field = 'desig_eng'
    field_allowed_values = ['Baltic Sea Protected Area (HELCOM)',
                            'Specially Protected Area (Cartagena Convention)',
                            'Marine Protected Area (CCAMLR)',
                            'Marine Protected Area (OSPAR)',
                            #Modified - WEDS - original was 'Site of...'
                            'Sites of Community Importance (Habitats Directive)',
                            'Special Protection Area (Birds Directive)',
                            #Modified - WEDS - the one below was added
                            'Special Areas of Conservation (Habitats Directive)',
                            'Specially Protected Areas of Mediterranean Importance (Barcelona Convention)']
    condition_field = 'desig_type'
    condition_crit = ['Regional']

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)

###########################################
#### 4.5. Invalid DESIG_TYPE - regional ###
###########################################

def invalid_desig_type_regional(wdpa_df, return_pid=False):
    '''
    Return True if DESIG_TYPE is unequal to 'Regional' while DESIG_ENG is an allowed 'Regional' value
    Return list of WDPA_PIDs where DESIG_TYPE is invalid, if return_pid is set True
    '''

    field = 'desig_type'
    field_allowed_values = ['Regional']
    condition_field = 'desig_eng'
    condition_crit = ['Baltic Sea Protected Area (HELCOM)',
                      'Specially Protected Area (Cartagena Convention)',
                      'Marine Protected Area (CCAMLR)',
                      'Marine Protected Area (OSPAR)',
                      'Site of Community Importance (Habitats Directive)',
                      'Special Protection Area (Birds Directive)',
                      'Specially Protected Areas of Mediterranean Importance (Barcelona Convention)']

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)


#################################################################################
#### 4.6. Invalid INT_CRIT & DESIG_ENG  - Ramsar Site & World Heritage Sites ####
#################################################################################

def invalid_int_crit_desig_eng_ramsar_whs(wdpa_df, return_pid=False):
    '''
    Return True if INT_CRIT is unequal to the allowed values (>1000 possible values)
    and DESIG_ENG equals 'Ramsar Site (...)' or 'World Heritage Site (...)'
    Return list of WDPA_PIDs where INT_CRIT is invalid, if return_pid is set True
    '''

    # Function to create the possible INT_CRIT combination
    def generate_combinations():
        import itertools
        collection = []
        INT_CRIT_ELEMENTS = ['(i)','(ii)','(iii)','(iv)',
                             '(v)','(vi)','(vii)','(viii)',
                             '(ix)','(x)']
        for length_combi in range(1, len(INT_CRIT_ELEMENTS)+1): # for 1 - 10 elements
            for combi in itertools.combinations(INT_CRIT_ELEMENTS, length_combi): # generate combinations
                collection.append(''.join(combi)) # append to list, remove the '' in each combination
        return collection

    # Arguments
    field = 'int_crit'
    field_allowed_values_extra = ['Not Reported']
    field_allowed_values =  generate_combinations() + field_allowed_values_extra
    condition_field = 'desig_eng'
    condition_crit = ['Ramsar Site, Wetland of International Importance',
                      'World Heritage Site (natural or mixed)']

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)

#################################
#### 4.7. Invalid DESIG_TYPE ####
#################################

def invalid_desig_type(wdpa_df, return_pid=False):
    '''
    Return True if DESIG_TYPE is not "National", "Regional", "International" or "Not Applicable"
    Return list of WDPA_PIDs where DESIG_TYPE is invalid, if return_pid is set True
    '''

    field = 'desig_type'
    field_allowed_values = ['National',
                            'Regional',
                            'International',
                            'Not Applicable']
    condition_field = ''
    condition_crit = []

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)

###############################
#### 4.8. Invalid IUCN_CAT ####
###############################

def invalid_iucn_cat(wdpa_df, return_pid=False):
    '''
    Return True if IUCN_CAT is not equal to allowed values
    Return list of WDPA_PIDs where IUCN_CAT is invalid, if return_pid is set True
    '''

    field = 'iucn_cat'
    field_allowed_values = ['Ia', 'Ib', 'II', 'III',
                            'IV', 'V', 'VI',
                            'Not Reported',
                            'Not Applicable',
                            'Not Assigned']
    condition_field = ''
    condition_crit = []

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)

#####################################################################
#### 4.9. Invalid IUCN_CAT - UNESCO-MAB and World Heritage Sites ####
#####################################################################

def invalid_iucn_cat_unesco_whs(wdpa_df, return_pid=False):
    '''
    Return True if IUCN_CAT is unqueal to 'Not Applicable'
    and DESIG_ENG is 'UNESCO-MAB (...)' or 'World Heritage Site (...)'
    Return list of WDPA_PIDs where IUCN_CAT is invalid, if return_pid is set True
    '''

    field = 'iucn_cat'
    field_allowed_values = ['Not Applicable']
    condition_field = 'desig_eng'
    condition_crit = ['UNESCO-MAB Biosphere Reserve',
                      'World Heritage Site (natural or mixed)']

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)

##############################
#### 4.10. Invalid MARINE ####
##############################

def invalid_marine(wdpa_df, return_pid=False):
    '''
    Return True if MARINE is not in [0,1,2]
    Return list of WDPA_PIDs where MARINE is invalid, if return_pid is set True
    '''

    field = 'marine'
    field_allowed_values = ['0','1','2']
    condition_field = ''
    condition_crit = []

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)

############################################
#### 4.11. Invalid NO_TAKE & MARINE = 0 ####
############################################

def invalid_no_take_marine0(wdpa_df, return_pid=False):
    '''
    Return True if NO_TAKE is not equal to 'Not Applicable' and MARINE = 0
    Return list of WDPA_PIDs where NO_TAKE is invalid, if return_pid is set True
    '''

    field = 'no_take'
    field_allowed_values = ['Not Applicable']
    condition_field = 'marine'
    condition_crit = ['0']

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)

################################################
#### 4.12. Invalid NO_TAKE & MARINE = [1,2] ####
################################################

def invalid_no_take_marine12(wdpa_df, return_pid=False):
    '''
    Return True if NO_TAKE is not in ['All', 'Part', 'None', 'Not Reported'] while MARINE = [1, 2]
    I.e. check whether coastal and marine sites (MARINE = [1, 2]) have an invalid NO_TAKE value.
    Return list of WDPA_PIDs where NO_TAKE is invalid, if return_pid is set True
    '''

    field = 'no_take'
    field_allowed_values = ['All', 'Part', 'None', 'Not Reported']
    condition_field = 'marine'
    condition_crit = ['1', '2']

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)

###########################################
#### 4.13. Invalid NO_TK_AREA & MARINE ####
###########################################

def invalid_no_tk_area_marine0(wdpa_df, return_pid=False):
    '''
    Return True if NO_TK_AREA is unequal to 0 while MARINE = 0
    Return list of WDPA_PIDs where NO_TAKE is invalid, if return_pid is set True
    '''

    field = 'no_tk_area'
    field_allowed_values = [0]
    condition_field = 'marine'
    condition_crit = ['0']

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)

############################################
#### 4.14. Invalid NO_TK_AREA & NO_TAKE ####
############################################

def invalid_no_tk_area_no_take(wdpa_df, return_pid=False):
    '''
    Return True if NO_TK_AREA is unequal to 0 while NO_TAKE = 'Not Applicable'
    Return list of WDPA_PIDs where NO_TK_AREA is invalid, if return_pid is set True
    '''

    field = 'no_tk_area'
    field_allowed_values = [0]
    condition_field = 'no_take'
    condition_crit = ['Not Applicable']

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)

##############################
#### 4.15. Invalid STATUS ####
##############################

'''
Return True if STATUS is unequal to any of the following allowed values:
["Proposed", "Designated", "Established"] for all sites except 2 designations (WH & Barcelona convention)
Return list of WDPA_PIDs where STATUS is invalid, if return_pid is set True
Note: "Inscribed" and "Adopted" are only valid for specific DESIG_ENG.
'''

def invalid_status(wdpa_df, return_pid=False):

    def value_isnot_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_cri, return_pid=False):
        # if condition_field and condition_cri are specified
        return_fields = ['wdpa_pid', field, condition_field]
        invalid_wdpa_pid = wdpa_df[(~wdpa_df[field].isin(field_allowed_values)) & (~wdpa_df[condition_field].isin(condition_cri))][return_fields].values

        if return_pid:
            # return list with invalid WDPA_PIDs
            return to_array_of_dict(invalid_wdpa_pid, condition_field)

        return len(invalid_wdpa_pid) > 0

    field = 'status'
    field_allowed_values = ['Proposed', 'Designated', 'Established']
    condition_field = 'desig_eng'
    condition_cri = ['World Heritage Site (natural or mixed)', 'Specially Protected Areas of Mediterranean Importance (Barcelona Convention)']

    return value_isnot_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_cri, return_pid)

########################################
#### 4.15.a Invalid STATUS WH Sites ####
########################################

def invalid_status_WH(wdpa_df, return_pid=False):
    '''
    Return True if STATUS is unequal to any of the following allowed values:
    ["Proposed", "Inscribed"] and DESIG_ENG is unqual to 'World Heritage Site (natural or mixed)'
    Return list of WDPA_PIDs where STATUS is invalid, if return_pid is set True
    Note: Not sure if Designated and Established are allowed for WH sites. For now allowed Propsoed and Inscribed only.
    '''

    field = 'status'
    field_allowed_values = ["Proposed", "Inscribed"]
    condition_field = 'desig_eng'
    condition_crit = ['World Heritage Site (natural or mixed)']

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)

####################################################
#### 4.15.b Invalid STATUS Barcelona Convention ####
####################################################

def invalid_status_Barca(wdpa_df, return_pid=False):
    '''
    Return True if STATUS is unequal to any of the following allowed values:
    ["Proposed", "Established", "Adopted"] and DESIG_ENG is unqual to 'Specially Protected Areas of Mediterranean Importance (Barcelona Convention)'
    Return list of WDPA_PIDs where STATUS is invalid, if return_pid is set True
    Note: Not sure if Designated and Established are allowed for Barcelona Convention sites. Removed.
    '''

    field = 'status'
    field_allowed_values = ["Proposed", "Adopted"]
    condition_field = 'desig_eng'
    condition_crit = ['Specially Protected Areas of Mediterranean Importance (Barcelona Convention)']

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)

#################################
#### 4.16. Invalid STATUS_YR ####
#################################

def invalid_status_yr(wdpa_df, return_pid=False):
    '''
    Return True if STATUS_YR is unequal to 0 or any year between 1750 and the current year
    Return list of WDPA_PIDs where STATUS_YR is invalid, if return_pid is set True
    '''

    field = 'status_yr'
    year = datetime.date.today().year # obtain current year
    # Modified - WEDS
    field_allowed_values = [0] + np.arange(1750, year + 1, 1).tolist() # make a list of all years, from 0 to current year
    #yearArray = [0] + np.arange(1750, year + 1, 1).tolist() # make a list of all years, from 0 to current year
    #field_allowed_values = [str(x) for x in yearArray] # change all integers to strings
    condition_field = ''
    condition_crit = []

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)

################################
#### 4.17. Invalid GOV_TYPE ####
################################

def invalid_gov_type(wdpa_df, return_pid=False):
    '''
    Return True if GOV_TYPE is invalid
    Return list of WDPA_PIDs where GOV_TYPE is invalid, if return_pid is set True
    '''

    field = 'gov_type'
    field_allowed_values = ['Federal or national ministry or agency',
                            'Sub-national ministry or agency',
                            'Government-delegated management',
                            'Transboundary governance',
                            'Collaborative governance',
                            'Joint governance',
                            'Individual landowners',
                            'Non-profit organisations',
                            'For-profit organisations',
                            'Indigenous peoples',
                            'Local communities',
                            'Not Reported']

    condition_field = ''
    condition_crit = []

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)

################################
#### 4.18. Invalid OWN_TYPE ####
################################

def invalid_own_type(wdpa_df, return_pid=False):
    '''
    Return True if OWN_TYPE is invalid
    Return list of WDPA_PIDs where OWN_TYPE is invalid, if return_pid is set True
    '''

    field = 'own_type'
    field_allowed_values = ['State',
                            'Communal',
                            'Individual landowners',
                            'For-profit organisations',
                            'Non-profit organisations',
                            'Joint ownership',
                            'Multiple ownership',
                            'Contested',
                            'Not Reported']
    condition_field = ''
    condition_crit = []

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)

#############################
#### 4.19. Invalid VERIF ####
#############################

def invalid_verif(wdpa_df, return_pid=False):
    '''
    Return True if VERIF is invalid
    Return list of WDPA_PIDs where VERIF is invalid, if return_pid is set True
    '''

    field = 'verif'
    field_allowed_values = ['State Verified',
                            'Expert Verified',
                            'Not Reported']
    condition_field = ''
    condition_crit = []

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)

###################################
#### 4.20. Invalid PARENT_ISO3 ####
###################################


def invalid_country_codes(wdpa_df, field, return_pid=False, allow_none=False): # Modified - WEDS

    iso3 = get_iso3()

    def _correct_iso3(field_value):
        #Added - WEDS
        if field_value is None:
#            return False
        # Modified - WEDS
            return allow_none
        for each in field_value.split(';'):
            if each in iso3:
                pass
            else:
                return False

        return True

    return_fields = ['wdpa_pid', field]
    invalid_wdpa_pid = wdpa_df[~wdpa_df[field].apply(_correct_iso3)][return_fields].values

    if return_pid:
        return to_array_of_dict(invalid_wdpa_pid, return_fields)

    else:
        return len(invalid_wdpa_pid) > 0

def invalid_parent_iso3(wdpa_df, return_pid=False):

    return invalid_country_codes(wdpa_df, 'parent_iso3', return_pid, True)  # Modified - WEDS

############################
#### 4.21. Invalid ISO3 ####
############################

def invalid_iso3(wdpa_df, return_pid=False):

    return invalid_country_codes(wdpa_df, 'iso3', return_pid)

###########################################
#### 4.22. Invalid STATUS & DESIG_TYPE ####
###########################################

def invalid_status_desig_type(wdpa_df, return_pid=False):
    '''
    Return True if STATUS is unequal to 'Established', while DESIG_TYPE = 'Not Applicable'
    Return list of WDPA_PIDs for which the STATUS is invalid
    '''

    field = 'status'
    field_allowed_values = ['Established']
    condition_field = 'desig_type'
    condition_crit = ['Not Applicable']

    return invalid_value_in_field(wdpa_df, field, field_allowed_values, condition_field, condition_crit, return_pid)

###############################################################
#### 5. Area invalid size: GIS or Reported area is invalid ####
###############################################################

#### Factory Function ####

def area_invalid_size(wdpa_df, field_small_area, field_large_area, return_pid=False):
    '''
    Factory Function: this generic function is to be linked to
    the family of 'area' input functions stated below. These latter
    functions are to give information on which fields to check and pull
    from the DataFrame. This function is the foundation of the others.
    This function checks the WDPA for invalid areas and returns a list of WDPA_PIDs
    that have invalid values for the specified field(s).
    Return True if the size of the small_area is invalid compared to large_area
    Return list of WDPA_PIDs where small_area is invalid compared to large_area,
    if return_pid is set True
    ## Arguments ##
    field_small_area  -- string of the field to check for size - supposedly smaller
    field_large_area  -- string of the field to check for size - supposedly larger
    ## Example ##
    area_invalid_size(
        wdpa_df,
        field_small_area="GIS_M_AREA",
        field_large_area="GIS_AREA",
        return_pid=True):
    '''

    size_threshold = 1.0001 # due to the rounding of numbers, there are many false positives without a threshold.

    return_fields = ['wdpa_pid', field_small_area, field_large_area]
    if field_small_area and field_large_area:
        invalid_wdpa_pid = wdpa_df[wdpa_df[field_small_area] >
                                 (size_threshold*wdpa_df[field_large_area])][return_fields].values

    else:
        raise Exception('ERROR: field(s) to test is (are) not specified')

    if return_pid:
        return to_array_of_dict(invalid_wdpa_pid, return_fields)

    return len(invalid_wdpa_pid) > 0

#### Input functions ####

######################################################
#### 5.1. Area invalid: NO_TK_AREA and REP_M_AREA ####
######################################################

def area_invalid_no_tk_area_rep_m_area(wdpa_df, return_pid=False):
    '''
    Return True if NO_TK_AREA is larger than REP_M_AREA
    Return list of WDPA_PIDs where NO_TK_AREA is larger than REP_M_AREA if return_pid=True
    '''

    field_small_area = 'no_tk_area'
    field_large_area = 'rep_m_area'

    return area_invalid_size(wdpa_df, field_small_area, field_large_area, return_pid)

######################################################
#### 5.2. Area invalid: NO_TK_AREA and GIS_M_AREA ####
######################################################

def area_invalid_no_tk_area_gis_m_area(wdpa_df, return_pid=False):
    '''
    Return True if NO_TK_AREA is larger than GIS_M_AREA
    Return list of WDPA_PIDs where NO_TK_AREA is larger than GIS_M_AREA if return_pid=True
    '''

    field_small_area = 'no_tk_area'
    field_large_area = 'gis_m_area'

    return area_invalid_size(wdpa_df, field_small_area, field_large_area, return_pid)

####################################################
#### 5.3. Area invalid: GIS_M_AREA and GIS_AREA ####
####################################################

def area_invalid_gis_m_area_gis_area(wdpa_df, return_pid=False):
    '''
    Return True if GIS_M_AREA is larger than GIS_AREA
    Return list of WDPA_PIDs where GIS_M_AREA is larger than GIS_AREA, if return_pid=True
    '''

    field_small_area = 'gis_m_area'
    field_large_area = 'gis_area'

    return area_invalid_size(wdpa_df, field_small_area, field_large_area, return_pid)

####################################################
#### 5.4. Area invalid: REP_M_AREA and REP_AREA ####
####################################################

def area_invalid_rep_m_area_rep_area(wdpa_df, return_pid=False):
    '''
    Return True if REP_M_AREA is larger than REP_AREA
    Return list of WDPA_PIDs where REP_M_AREA is larger than REP_AREA, if return_pid=True
    '''

    field_small_area = 'rep_m_area'
    field_large_area = 'rep_area'

    return area_invalid_size(wdpa_df, field_small_area, field_large_area, return_pid)

#################################
#### 6. Forbidden characters ####
#################################

#### Factory Function ####

def forbidden_character(wdpa_df, check_field, return_pid=False):
    '''
    Factory Function: this generic function is to be linked to
    the family of 'forbidden character' input functions stated below. These latter
    functions are to give information on which fields to check and pull
    from the DataFrame. This function is the foundation of the others.
    This function checks the WDPA for forbidden characters and returns a list of WDPA_PIDs
    that have invalid values for the specified field(s).
    Return True if forbidden characters (specified below) are found in the DataFrame
    Return list of WDPA_PID where forbidden characters occur, if
    return_pid is set True
    ## Arguments ##
    check_field -- string of the field to check for forbidden characters
    ## Example ##
    forbidden_character(
        wdpa_df,
        check_field="DESIG_ENG",
        return_pid=True):
    '''

    # Import regular expression package and the forbidden characters
    forbidden_characters = ['<','>','?','*','\r','\n']
    forbidden_characters_esc = [re.escape(s) for s in forbidden_characters]

    pattern = '|'.join(forbidden_characters_esc)

    # Obtain the WDPA_PIDs with forbidden characters
    # remove those with nas
    wdpa_df = wdpa_df.dropna()
    return_fields = ['wdpa_pid', check_field]
    invalid_wdpa_pid = wdpa_df[wdpa_df[check_field].str.contains(pattern, case=False)][return_fields].values

    if return_pid:
        return to_array_of_dict(invalid_wdpa_pid, return_fields)

    return len(invalid_wdpa_pid) > 0


#########################################
#### 6.1. Forbidden character - NAME ####
#########################################

def forbidden_character_name(wdpa_df, return_pid=False):
    '''
    Capture forbidden characters in the field 'NAME'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing forbidden characters in field 'NAME'
    '''

    check_field = 'name'

    return forbidden_character(wdpa_df, check_field, return_pid)

##############################################
#### 6.2. Forbidden character - ORIG_NAME ####
##############################################

def forbidden_character_orig_name(wdpa_df, return_pid=False):
    '''
    Capture forbidden characters in the field 'ORIG_NAME'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing forbidden characters in field 'ORIG_NAME'
    '''

    check_field = 'orig_name'

    return forbidden_character(wdpa_df, check_field, return_pid)

##########################################
#### 6.3. Forbidden character - DESIG ####
##########################################

def forbidden_character_desig(wdpa_df, return_pid=False):
    '''
    Capture forbidden characters in the field 'DESIG'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing forbidden characters in field 'DESIG'
    '''

    check_field = 'desig'

    return forbidden_character(wdpa_df, check_field, return_pid)

##############################################
#### 6.4. Forbidden character - DESIG_ENG ####
##############################################

def forbidden_character_desig_eng(wdpa_df, return_pid=False):
    '''
    Capture forbidden characters in the field 'DESIG_ENG'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing forbidden characters in field 'DESIG_ENG'
    '''

    check_field = 'desig_eng'

    return forbidden_character(wdpa_df, check_field, return_pid)

##############################################
#### 6.5. Forbidden character - MANG_AUTH ####
##############################################

def forbidden_character_mang_auth(wdpa_df, return_pid=False):
    '''
    Capture forbidden characters in the field 'MANG_AUTH'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing forbidden characters in field 'MANG_AUTH'
    '''

    check_field = 'mang_auth'

    return forbidden_character(wdpa_df, check_field, return_pid)

##############################################
#### 6.6. Forbidden character - MANG_PLAN ####
##############################################

def forbidden_character_mang_plan(wdpa_df, return_pid=False):
    '''
    Capture forbidden characters in the field 'MANG_PLAN'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing forbidden characters in field 'MANG_PLAN'
    '''

    check_field = 'mang_plan'

    return forbidden_character(wdpa_df, check_field, return_pid)

############################################
#### 6.7. Forbidden character - SUB_LOC ####
############################################

def forbidden_character_sub_loc(wdpa_df, return_pid=False):
    '''
    Capture forbidden characters in the field 'SUB_LOC'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing forbidden characters in field 'SUB_LOC'
    '''

    check_field = 'sub_loc'

    return forbidden_character(wdpa_df, check_field, return_pid)

########################
#### 7. NaN present ####
########################

#### Factory Function ####

def nan_present(wdpa_df, check_field, return_pid=False):
    '''
    Factory Function: this generic function is to be linked to
    the family of 'nan_present' input functions stated below. These latter
    functions are to give information on which fields to check and pull
    from the DataFrame. This function is the foundation of the others.
    This function checks the WDPA for NaN / NA / None values and returns
    a list of WDPA_PIDs that have invalid values for the specified field(s).
    Return True if NaN / NA values are found in the DataFrame
    Return list of WDPA_PID where forbidden characters occur, if
    return_pid is set True
    ## Arguments ##
    check_field -- string of field to be checked for NaN / NA values
    ## Example ##
    na_present(
        wdpa_df,
        check_field="DESIG_ENG",
        return_pid=True):
    '''
    return_fields = ['wdpa_pid', check_field]
    invalid_wdpa_pid = wdpa_df[pd.isna(wdpa_df[check_field])][return_fields].values

    if return_pid:
        return to_array_of_dict(invalid_wdpa_pid, return_fields)

    return len(invalid_wdpa_pid) > 0

#### Input functions ####

#################################
#### 7.1. NaN present - NAME ####
#################################

def ivd_nan_present_name(wdpa_df, return_pid=False):
    '''
    Capture NaN / NA in the field 'NAME'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing NaN / NA in field 'NAME'
    '''

    check_field = 'name'

    return nan_present(wdpa_df, check_field, return_pid)

######################################
#### 7.2. NaN present - ORIG_NAME ####
######################################

def ivd_nan_present_orig_name(wdpa_df, return_pid=False):
    '''
    Capture NaN / NA in the field 'ORIG_NAME'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing NaN / NA in field 'ORIG_NAME'
    '''

    check_field = 'orig_name'

    return nan_present(wdpa_df, check_field, return_pid)

##################################
#### 7.3. NaN present - DESIG ####
##################################

def ivd_nan_present_desig(wdpa_df, return_pid=False):
    '''
    Capture NaN / NA in the field 'DESIG'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing NaN / NA in field 'DESIG'
    '''

    check_field = 'desig'

    return nan_present(wdpa_df, check_field, return_pid)

######################################
#### 7.4. NaN present - DESIG_ENG ####
######################################

def ivd_nan_present_desig_eng(wdpa_df, return_pid=False):
    '''
    Capture NaN / NA in the field 'DESIG_ENG'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing NaN / NA in field 'DESIG_ENG'
    '''

    check_field = 'desig_eng'

    return nan_present(wdpa_df, check_field, return_pid)

######################################
#### 7.5. NaN present - MANG_AUTH ####
######################################

def ivd_nan_present_mang_auth(wdpa_df, return_pid=False):
    '''
    Capture NaN / NA in the field 'MANG_AUTH'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing NaN / NA in field 'MANG_AUTH'
    '''

    check_field = 'mang_auth'

    return nan_present(wdpa_df, check_field, return_pid)

######################################
#### 7.6. NaN present - MANG_PLAN ####
######################################

def ivd_nan_present_mang_plan(wdpa_df, return_pid=False):
    '''
    Capture NaN / NA in the field 'MANG_PLAN'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing NaN / NA in field 'MANG_PLAN'
    '''

    check_field = 'mang_plan'

    return nan_present(wdpa_df, check_field, return_pid)

####################################
#### 7.7. NaN present - SUB_LOC ####
####################################

def ivd_nan_present_sub_loc(wdpa_df, return_pid=False):
    '''
    Capture NaN / NA in the field 'SUB_LOC'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing NaN / NA in field 'SUB_LOC'
    '''

    check_field = 'sub_loc'

    return nan_present(wdpa_df, check_field, return_pid)

#######################################
#### 7.8. NaN present - METADATAID ####
#######################################

def ivd_nan_present_metadataid(wdpa_df, return_pid=False):
    '''
    Capture NaN / NA in the field 'METADATAID'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing NaN / NA in field 'METADATAID'
    '''

    check_field = 'metadataid'

    return nan_present(wdpa_df, check_field, return_pid)

#######################################
#### 7.9. NaN present - INT_CRIT ######
#######################################

def ivd_nan_present_int_crit(wdpa_df, return_pid=False):
    '''
    Capture NaN / NA in the field 'INT_CRIT'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing NaN / NA in field 'INT_CRIT'
    '''

    check_field = 'int_crit'

    return nan_present(wdpa_df, check_field, return_pid)

#######################################
#### 7.10. NaN present - REP_M_AREA ###
#######################################

def ivd_nan_present_rep_m_area(wdpa_df, return_pid=False):
    '''
    Capture NaN / NA in the field 'REP_M_AREA'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing NaN / NA in field 'REP_M_AREA'
    '''

    check_field = 'rep_m_area'

    return nan_present(wdpa_df, check_field, return_pid)

#######################################
#### 7.11. NaN present - REP_AREA ###
#######################################

def ivd_nan_present_rep_area(wdpa_df, return_pid=False):
    '''
    Capture NaN / NA in the field 'REP_AREA'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing NaN / NA in field 'REP_AREA'
    '''

    check_field = 'rep_area'

    return nan_present(wdpa_df, check_field, return_pid)

#######################################
#### 7.12. NaN present - GIS_M_AREA ###
#######################################

def ivd_nan_present_gis_m_area(wdpa_df, return_pid=False):
    '''
    Capture NaN / NA in the field 'GIS_M_AREA'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing NaN / NA in field 'GIS_M_AREA'
    '''

    check_field = 'gis_m_area'

    return nan_present(wdpa_df, check_field, return_pid)

#######################################
#### 7.13. NaN present - GIS_AREA ###
#######################################

def ivd_nan_present_gis_area(wdpa_df, return_pid=False):
    '''
    Capture NaN / NA in the field 'GIS_AREA'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing NaN / NA in field 'GIS_AREA'
    '''

    check_field = 'gis_area'

    return nan_present(wdpa_df, check_field, return_pid)

#######################################
#### 7.14. NaN present - NO_TK_AREA ###
#######################################

def ivd_nan_present_no_tk_area(wdpa_df, return_pid=False):
    '''
    Capture NaN / NA in the field 'NO_TK_AREA'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing NaN / NA in field 'NO_TK_AREA'
    '''

    check_field = 'no_tk_area'

    return nan_present(wdpa_df, check_field, return_pid)

#######################################
#### 7.15. NaN present - STATUS_YR ###
#######################################

def ivd_nan_present_status_yr(wdpa_df, return_pid=False):
    '''
    Capture NaN / NA in the field 'STATUS_YR'
    Input: WDPA in pandas DataFrame
    Output: list with WDPA_PIDs containing NaN / NA in field 'STATUS_YR'
    '''

    check_field = 'status_yr'

    return nan_present(wdpa_df, check_field, return_pid)

#################################################################
#### 8. METADATAID: WDPA and Source Table (in Integrity tool) ####
#################################################################

#######################################################################
#### 8.1. Invalid: METADATAID present in WDPA, not in Source Table ####
#######################################################################

# def invalid_metadataid_not_in_source_table(wdpa_df, wdpa_source, return_pid=False):
#     '''
#     Return True if METADATAID is present in the WDPA but not in the Source Table
#     Return list of WDPA_PIDs for which the METADATAID is not present in the Source Table
#     '''

#     field = 'METADATAID'

    ########## OPTIONAL ##########
    #### Remove METADATAID = 840 (Russian sites that are restricted and not in Source Table)
    #condition_crit = [840]
    # Remove METADATAID = 840 from the WDPA
    #wdpa_df_no840 = wdpa_df[wdpa_df[field[0]] != condition_crit[0]]
    #invalid_wdpa_pid = wdpa_df_no840[~wdpa_df_no840[field[0]].isin(
    #                                  wdpa_source[field[0]].values)]['WDPA_PID'].values
    ##############################

    # Find invalid WDPA_PIDs
#     invalid_wdpa_pid = wdpa_df[~wdpa_df[field].isin(
#                                 wdpa_source[field].values)]['WDPA_PID'].values

#     if return_pid:
#         return invalid_wdpa_pid

#     return invalid_wdpa_pid > 0

#######################################################################
#### 8.2. Invalid: METADATAID present in Source Table, not in WDPA ####
#### Note: output is METADATAIDs.                                  ####
#######################################################################

# def invalid_metadataid_not_in_wdpa(wdpa_df, wdpa_point, wdpa_source, return_pid=False):
#     '''
#     Return True if METADATAID is present in the Source Table but not in the Source Table
#     Return list of METADATAIDs for which the METADATAID is not present in the Source Table
#     '''

#     field = ['METADATAID']

#     # Concatenate all METADATAIDs of the WDPA point and poly tables
#     field_allowed_values = np.concatenate((wdpa_df[field[0]].values,wdpa_point[field[0]].values),axis=0)

#     ########## OPTIONAL ##########
#     # Remove METADATA = 840 (Russian sites that are restricted and not in Source Table)
#     #metadataid_wdpa = np.concatenate((wdpa_df[field[0]].values,wdpa_point[field[0]].values),axis=0)
#     #field_allowed_values = np.delete(metadataid_wdpa, np.where(metadataid_wdpa == 840), axis=0)
#     #######################

#     # Find METADATAIDs in the Source Table that are not present in the WDPA
#     invalid_metadataid = wdpa_source[~wdpa_source[field[0]].isin(field_allowed_values)]['METADATAID'].values

#     if return_pid:
#         return invalid_metadataid

#     return len(invalid_metadataid) > 0
def process(fn, output_dict, *args):
    print(fn.__name__)
    val = fn(*args)
    output_dict[fn.__name__] = val
    output_dict['Checks raised'] += len(val)

class QAVerifier():

    @staticmethod
    def verify(metadata_id):
        start_time = time.time()
        df = arcgis_table_to_df(metadata_id)
        if df.empty:
            return ""
        df_polygons_only = polygons_only(df)
        output_dict = {'Checks raised': 0}
        process(invalid_desig_eng_iucn_cat_other, output_dict, df, True)
        process(duplicate_wdpa_pid, output_dict, df, True)
        process(invalid_int_crit_desig_eng_other, output_dict, df, True)
        process(invalid_desig_eng_iucn_cat_other, output_dict, df, True)
        process(inconsistent_orig_name_same_wdpaid, output_dict, df, True)
        process(inconsistent_desig_same_wdpaid, output_dict, df, True)
        process(inconsistent_desig_eng_same_wdpaid, output_dict, df, True)
        process(inconsistent_desig_type_same_wdpaid, output_dict, df, True)
        process(inconsistent_int_crit_same_wdpaid, output_dict, df, True)
        process(inconsistent_no_take_same_wdpaid, output_dict, df, True)
        process(inconsistent_status_same_wdpaid, output_dict, df, True)
        process(inconsistent_status_yr_same_wdpaid, output_dict, df, True)
        process(inconsistent_gov_type_same_wdpaid, output_dict, df, True)
        process(inconsistent_own_type_same_wdpaid, output_dict, df, True)
        process(inconsistent_mang_auth_same_wdpaid, output_dict, df, True)
        process(inconsistent_mang_plan_same_wdpaid, output_dict, df, True)
        process(invalid_no_take_no_tk_area_rep_m_area, output_dict, df, True)
        process(inconsistent_verif_same_wdpaid, output_dict, df, True)
        process(inconsistent_metadataid_same_wdpaid, output_dict, df, True)
        process(inconsistent_sub_loc_same_wdpaid, output_dict, df, True)
        process(inconsistent_parent_iso3_same_wdpaid, output_dict, df, True)
        process(inconsistent_iso3_same_wdpaid, output_dict, df, True)

        process(invalid_pa_def, output_dict, df, True)
        process(invalid_desig_eng_international, output_dict, df, True)
        process(invalid_desig_type_international, output_dict, df, True)
        process(invalid_desig_eng_regional, output_dict, df, True)
        process(invalid_desig_type_regional, output_dict, df, True)
        process(invalid_int_crit_desig_eng_ramsar_whs, output_dict, df, True)

        process(invalid_desig_type, output_dict, df, True)
        process(invalid_iucn_cat, output_dict, df, True)
        process(invalid_iucn_cat_unesco_whs, output_dict, df, True)
        process(invalid_marine, output_dict, df, True)
        process(invalid_no_take_marine0, output_dict, df, True)
        process(invalid_no_take_marine12, output_dict, df, True)
        process(invalid_no_tk_area_marine0, output_dict, df, True)
        process(invalid_no_tk_area_no_take, output_dict, df, True)

        process(invalid_status, output_dict, df, True)
        process(invalid_status_WH, output_dict, df, True)
        process(invalid_status_Barca, output_dict, df, True)
        process(invalid_status_yr, output_dict, df, True)
        process(invalid_gov_type, output_dict, df, True)
        process(invalid_own_type, output_dict, df, True)

        process(invalid_verif, output_dict, df, True)
        process(invalid_parent_iso3, output_dict, df, True)
        process(invalid_iso3, output_dict, df, True)
        process(invalid_status_desig_type, output_dict, df, True)
        process(forbidden_character_name, output_dict, df, True)
        process(forbidden_character_orig_name, output_dict, df, True)
        process(forbidden_character_desig, output_dict, df, True)
        process(forbidden_character_mang_auth, output_dict, df, True)
        process(forbidden_character_mang_plan, output_dict, df, True)
        process(forbidden_character_sub_loc, output_dict, df, True)

        process(ivd_nan_present_name, output_dict, df, True)
        process(ivd_nan_present_orig_name, output_dict, df, True)
        process(ivd_nan_present_desig, output_dict, df, True)
        process(ivd_nan_present_desig_eng, output_dict, df, True)
        process(ivd_nan_present_mang_auth, output_dict, df, True)
        process(ivd_nan_present_mang_plan, output_dict, df, True)
        process(ivd_nan_present_sub_loc, output_dict, df, True)
        process(ivd_nan_present_metadataid, output_dict, df, True)
        process(ivd_nan_present_int_crit, output_dict, df, True)
        process(ivd_nan_present_rep_m_area, output_dict, df, True)
        process(ivd_nan_present_gis_m_area, output_dict, df, True)
        process(ivd_nan_present_rep_area, output_dict, df, True)
        process(ivd_nan_present_gis_area, output_dict, df, True)
        process(ivd_nan_present_no_tk_area, output_dict, df, True)
        process(ivd_nan_present_status_yr, output_dict, df, True)

        process(area_invalid_marine, output_dict, df_polygons_only, True)
        process(area_invalid_too_large_rep, output_dict, df_polygons_only, True)
        process(area_invalid_too_large_gis_m, output_dict, df_polygons_only, True)
        process(area_invalid_too_large_rep_m, output_dict, df_polygons_only, True)
        process(area_invalid_gis_area, output_dict, df_polygons_only, True)
        process(area_invalid_rep_area, output_dict, df_polygons_only, True)
        process(area_invalid_big_rep_area, output_dict, df_polygons_only, True)
        process(area_invalid_rep_m_area_marine12, output_dict, df_polygons_only, True)
        process(area_invalid_gis_m_area_marine12, output_dict, df_polygons_only, True)

        process(area_invalid_no_tk_area_rep_m_area, output_dict, df_polygons_only, True)
        process(area_invalid_no_tk_area_gis_m_area, output_dict, df_polygons_only, True)
        process(area_invalid_gis_m_area_gis_area, output_dict, df_polygons_only, True)
        process(area_invalid_rep_m_area_rep_area, output_dict, df_polygons_only, True)
        duration = time.time() - start_time
        output_dict['Time taken'] = duration
        return output_dict