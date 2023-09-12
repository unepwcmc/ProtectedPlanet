/* Install data for fpic_cat
INSERT INTO stg_fpic_cat(code, description, originator_id) VALUES('0', 'No', 10000);
INSERT INTO stg_fpic_cat(code, description, originator_id) VALUES('1', 'Yes', 10000);

/* Install data for case_study_published_cat
INSERT INTO stg_case_study_published_cat(code, description, originator_id) VALUES('0', 'No', 10000);
INSERT INTO stg_case_study_published_cat(code, description, originator_id) VALUES('1', 'Yes', 10000);
INSERT INTO stg_case_study_published_cat(code, description, originator_id) VALUES('Pending', 'If they selected ''yes'' in the questionnaire, but it is not online yet', 10000);

/* Install data for icca_peer-reviewed_cat
INSERT INTO stg_peer_reviewed_cat(code, description, originator_id) VALUES('0', 'No', 10000);
INSERT INTO stg_peer_reviewed_cat(code, description, originator_id) VALUES('1', 'Yes', 10000);

/* Install data for no_take_permanency_cat
INSERT INTO stg_no_take_permanency_cat(code, description, originator_id) VALUES('Permanent', 'Permanent', 10000);
INSERT INTO stg_no_take_permanency_cat(code, description, originator_id) VALUES('Temporary', 'Temporary', 10000);
INSERT INTO stg_no_take_permanency_cat(code, description, originator_id) VALUES('Seasonal', 'Seasonal', 10000);
INSERT INTO stg_no_take_permanency_cat(code, description, originator_id) VALUES('Not Reported', 'Not Reported', 10000);
INSERT INTO stg_no_take_permanency_cat(code, description, originator_id) VALUES('Not Applicable', 'Not Applicable', 10000);

/* Install data for governance_council_cat
INSERT INTO stg_governance_council_cat(code, description, originator_id) VALUES('Inherited', 'Inherited', 10000);
INSERT INTO stg_governance_council_cat(code, description, originator_id) VALUES('Elected', 'Elegated', 10000);
INSERT INTO stg_governance_council_cat(code, description, originator_id) VALUES('Delegated', '(e.g., members are appointed by elders)', 10000);
INSERT INTO stg_governance_council_cat(code, description, originator_id) VALUES('Not Reported', 'Not Reported', 10000);
INSERT INTO stg_governance_council_cat(code, description, originator_id) VALUES('Other', 'Further description needed', 10000);

/* Install data for icca_governance_type_cat
INSERT INTO stg_icca_governance_type_cat(code, description, originator_id) VALUES('Indigenous peoples', 'Indigenous peoples', 10000);
INSERT INTO stg_icca_governance_type_cat(code, description, originator_id) VALUES('Local communities', 'Local communities', 10000);
INSERT INTO stg_icca_governance_type_cat(code, description, originator_id) VALUES('Collaborative governance', 'Indigenous peoples', 10000);
INSERT INTO stg_icca_governance_type_cat(code, description, originator_id) VALUES('Joint governance', 'Indigenous peoples', 10000);
INSERT INTO stg_icca_governance_type_cat(code, description, originator_id) VALUES('Not Reported', 'Not Reported', 10000);
INSERT INTO stg_icca_governance_type_cat(code, description, originator_id) VALUES('Other', 'Further description needed', 10000);

/* Install data for internal_recognition_cat
INSERT INTO stg_internal_recognition_cat(code, description, originator_id) VALUES('Community constitution, by-laws or protocols', 'Other', 10000);
INSERT INTO stg_internal_recognition_cat(code, description, originator_id) VALUES('Biocultural (or other) protocol', 'Other', 10000);
INSERT INTO stg_internal_recognition_cat(code, description, originator_id) VALUES('Proclamation/ declaration', 'Other', 10000);
INSERT INTO stg_internal_recognition_cat(code, description, originator_id) VALUES('Cultural event or celebration', 'Other', 10000);
INSERT INTO stg_internal_recognition_cat(code, description, originator_id) VALUES('Provision of information to a national registry or database on ICCAs', 'Other', 10000);
INSERT INTO stg_internal_recognition_cat(code, description, originator_id) VALUES('Recommendation that the ICCA be recognised in national or sub-national law', 'Other', 10000);
INSERT INTO stg_internal_recognition_cat(code, description, originator_id) VALUES('Not Reported', 'Not Reported', 10000);
INSERT INTO stg_internal_recognition_cat(code, description, originator_id) VALUES('Other', 'Further description needed', 10000);

/* Install data for external_recognition_cat
INSERT INTO stg_external_recognition_cat(code, description, originator_id) VALUES('National/ federal law', 'National/ federal law', 10000);
INSERT INTO stg_external_recognition_cat(code, description, originator_id) VALUES('Sub-national law (regional/ provincial/ municipal)', 'Sub-national law (regional/ provincial/ municipal)', 10000);
INSERT INTO stg_external_recognition_cat(code, description, originator_id) VALUES('Other laws', 'Further description needed', 10000);
INSERT INTO stg_external_recognition_cat(code, description, originator_id) VALUES('Civil society forum', 'Civil society forum', 10000);
INSERT INTO stg_external_recognition_cat(code, description, originator_id) VALUES('Recognition by other local communities or indigenous peoples', 'Recognition by other local communities or indigenous peoples', 10000);
INSERT INTO stg_external_recognition_cat(code, description, originator_id) VALUES('Award of merit', 'e.g. the Equator Initiative', 10000);
INSERT INTO stg_external_recognition_cat(code, description, originator_id) VALUES('Media coverage', 'Media Coverage', 10000);
INSERT INTO stg_external_recognition_cat(code, description, originator_id) VALUES('Partnerships involving commercial production/ interests', 'e.g. tourism, contracts with businesses for the productions of crops', 10000);
INSERT INTO stg_external_recognition_cat(code, description, originator_id) VALUES('Other', 'Further description needed', 10000);

/* Install data for community_decisions_cat
INSERT INTO stg_community_decisions_cat(code, description, originator_id) VALUES('Through a governing body that represents the entire indigenous people', '', 10000);
INSERT INTO stg_community_decisions_cat(code, description, originator_id) VALUES('Through a governing body that represents the entire local community', '', 10000);
INSERT INTO stg_community_decisions_cat(code, description, originator_id) VALUES('Through a governing body of elders within the indigenous people or local community', '', 10000);
INSERT INTO stg_community_decisions_cat(code, description, originator_id) VALUES('Through a governing body of women within the indigenous people or local community', '', 10000);
INSERT INTO stg_community_decisions_cat(code, description, originator_id) VALUES('Through a governing body of youth within the indigenous people or local community', '', 10000);
INSERT INTO stg_community_decisions_cat(code, description, originator_id) VALUES('Through a governing body of resource users within the indigenous people or local community', '', 10000);
INSERT INTO stg_community_decisions_cat(code, description, originator_id) VALUES('It depends on the situation or issue to be decided', 'Further description needed', 10000);
INSERT INTO stg_community_decisions_cat(code, description, originator_id) VALUES('Other', 'Further description needed', 10000);
INSERT INTO stg_community_decisions_cat(code, description, originator_id) VALUES('Not Reported', '', 10000);

/* Install data for management_plan_format_cat
INSERT into stg_management_plan_format_cat(code, description, originator_id) VALUES('Written', 'Written', 10000);
INSERT into stg_management_plan_format_cat(code, description, originator_id) VALUES('Oral', 'Oral', 10000);
INSERT into stg_management_plan_format_cat(code, description, originator_id) VALUES('Other', 'Further description needed', 10000);
INSERT into stg_management_plan_format_cat(code, description, originator_id) VALUES('Not Reported', 'Not Reported', 10000);

/* Install data for community_identity_cat
INSERT INTO stg_community_identity_cat(code, description, originator_id) VALUES('Indigenous people', 'Indigenous people', 10000);
INSERT INTO stg_community_identity_cat(code, description, originator_id) VALUES('Local community', 'Local community', 10000);
INSERT INTO stg_community_identity_cat(code, description, originator_id) VALUES('Minotiry', 'Minority', 10000);
INSERT INTO stg_community_identity_cat(code, description, originator_id) VALUES('Other', 'Further description needed', 10000);
INSERT INTO stg_community_identity_cat(code, description, originator_id) VALUES('Not Reported', 'Not Reported', 10000);

/* Install data for community_mobility_cat
INSERT INTO stg_community_mobility_cat(code, description, originator_id) VALUES('Permanent settlement', 'Permanent settlement', 10000);
INSERT INTO stg_community_mobility_cat(code, description, originator_id) VALUES('Mobile livelihood only', 'Mobile livelihood only', 10000);
INSERT INTO stg_community_mobility_cat(code, description, originator_id) VALUES('Seasonal mobility between settlements', 'Seasonal mobility between settlements', 10000);
INSERT INTO stg_community_mobility_cat(code, description, originator_id) VALUES('Other', 'Further description needed', 10000);
INSERT INTO stg_community_mobility_cat(code, description, originator_id) VALUES('Not Reported', 'Not Reported', 10000);

/* Install data for community_mobility_beyond_icca_cat
INSERT INTO stg_community_mobility_beyond_icca_cat(code, description, originator_id) VALUES('Yes', 'Yes', 10000);
INSERT INTO stg_community_mobility_beyond_icca_cat(code, description, originator_id) VALUES('No', 'No', 10000);
INSERT INTO stg_community_mobility_beyond_icca_cat(code, description, originator_id) VALUES('N/A', 'N/A', 10000);
INSERT INTO stg_community_mobility_beyond_icca_cat(code, description, originator_id) VALUES('Not Reported', 'Not Reported', 10000);
INSERT INTO stg_community_mobility_beyond_icca_cat(code, description, originator_id) VALUES('Other - for migration only', 'Invalid', 10000);

/* Install data for habitat_types_global_cat
INSERT into stg_habitat_types_global_cat(code, description, originator_id) VALUES('Tropical & Subtropical Moist Broadleaf Forests','Tropical & Subtropical Moist Broadleaf Forests',10000);
INSERT into stg_habitat_types_global_cat(code, description, originator_id) VALUES('Tropical & Subtropical Dry Broadleaf Forests','Tropical & Subtropical Dry Broadleaf Forests',10000);
INSERT into stg_habitat_types_global_cat(code, description, originator_id) VALUES('Tropical & Subtropical Coniferous Forests','Tropical & Subtropical Coniferous Forests',10000);
INSERT into stg_habitat_types_global_cat(code, description, originator_id) VALUES('Temperate Coniferous Forests','Temperate Coniferous Forests',10000);
INSERT into stg_habitat_types_global_cat(code, description, originator_id) VALUES('Boreal Forests/Taiga','Boreal Forests/Taiga',10000);
INSERT into stg_habitat_types_global_cat(code, description, originator_id) VALUES('Tropical & Subtropical Grasslands, Savannas & Shrubland','Tropical & Subtropical Grasslands, Savannas & Shrubland',10000);
INSERT into stg_habitat_types_global_cat(code, description, originator_id) VALUES('Temperate Grasslands, Savannas & Shrublands','Temperate Grasslands, Savannas & Shrublands',10000);
INSERT into stg_habitat_types_global_cat(code, description, originator_id) VALUES('Flooded Grasslands & Savannas','Flooded Grasslands & Savannas',10000);
INSERT into stg_habitat_types_global_cat(code, description, originator_id) VALUES('Montane Grasslands & Shrublands','Montane Grasslands & Shrublands',10000);
INSERT into stg_habitat_types_global_cat(code, description, originator_id) VALUES('Tundra','Tundra',10000);
INSERT into stg_habitat_types_global_cat(code, description, originator_id) VALUES('Mediterranean Forests, Woodlands & Scrub','Mediterranean Forests, Woodlands & Scrub',10000);
INSERT into stg_habitat_types_global_cat(code, description, originator_id) VALUES('Deserts & Xeric Shrublands','Deserts & Xeric Shrublands',10000);
INSERT into stg_habitat_types_global_cat(code, description, originator_id) VALUES('Desert','Desert',10000);
INSERT into stg_habitat_types_global_cat(code, description, originator_id) VALUES('Mangroves','Mangroves',10000);
INSERT into stg_habitat_types_global_cat(code, description, originator_id) VALUES('Freshwater','Freshwater',10000);
INSERT into stg_habitat_types_global_cat(code, description, originator_id) VALUES('Marine','Marine',10000);
INSERT into stg_habitat_types_global_cat(code, description, originator_id) VALUES('Corals','Corals',10000);
INSERT into stg_habitat_types_global_cat(code, description, originator_id) VALUES('Not Reported','Nor Reported',10000);
INSERT into stg_habitat_types_global_cat(code, description, originator_id) VALUES('Other - for migration only','Invalid',10000);

/* Install data for icca_objectives_cat
INSERT into stg_icca_objectives_cat(code, description, originator_id) VALUES('Supporting traditional livelihoods','Supporting traditional livelihoods', 10000);
INSERT into stg_icca_objectives_cat(code, description, originator_id) VALUES('Supporting sustainable livelihoods','Supporting sustainable livelihoods', 10000);
INSERT into stg_icca_objectives_cat(code, description, originator_id) VALUES('Maintaining and enhancing natural resources','Maintaining and enhancing natural resources', 10000);
INSERT into stg_icca_objectives_cat(code, description, originator_id) VALUES('Maintaining cultural/spiritual values','Maintaining cultural/spiritual values', 10000);
INSERT into stg_icca_objectives_cat(code, description, originator_id) VALUES('Protection of spiritual/ sacred sites','Protection of spiritual/ sacred sites', 10000);
INSERT into stg_icca_objectives_cat(code, description, originator_id) VALUES('Conservation of specific species or biodiversity in general','Conservation of specific species or biodiversity in general', 10000);
INSERT into stg_icca_objectives_cat(code, description, originator_id) VALUES('Land ownership security','Land ownership security', 10000);
INSERT into stg_icca_objectives_cat(code, description, originator_id) VALUES('Territorial security','Territorial security', 10000);
INSERT into stg_icca_objectives_cat(code, description, originator_id) VALUES('Increasing rights for self-determination and empowerment','Increasing rights for self-determination and empowerment', 10000);
INSERT into stg_icca_objectives_cat(code, description, originator_id) VALUES('Developing opportunities for tourism','Developing opportunities for tourism', 10000);
INSERT into stg_icca_objectives_cat(code, description, originator_id) VALUES('Incentivising youth to remain in the area, preventing depopulation, ageing of the population and other demographic problems','Incentivising youth to remain in the area, preventing depopulation, ageing of the population and other demographic problems', 10000);
INSERT into stg_icca_objectives_cat(code, description, originator_id) VALUES('Other','Further description needed', 10000);

/* Install data for resource_use_cat
INSERT INTO stg_resource_use_cat(code, description, originator_id) VALUES('Subsistence','Subsistence',10000);
INSERT INTO stg_resource_use_cat(code, description, originator_id) VALUES('Cultural','e.g. in traditional ceremonies or medicines, or as traditional housing materials',10000);
INSERT INTO stg_resource_use_cat(code, description, originator_id) VALUES('Tourism','e.g. to promote eco-tourism within the ICCA',10000);
INSERT INTO stg_resource_use_cat(code, description, originator_id) VALUES('Small-scale commercial','e.g. sale of natural resources for income',10000);
INSERT INTO stg_resource_use_cat(code, description, originator_id) VALUES('Not Reported','Not Reported',10000);
INSERT INTO stg_resource_use_cat(code, description, originator_id) VALUES('Other','Further description needed',10000);

/* Install data for resource_use_in_community_cat
INSERT INTO stg_resource_use_in_community_cat(code, description, originator_id) VALUES('Yes','Yes',10000);
INSERT INTO stg_resource_use_in_community_cat(code, description, originator_id) VALUES('No','No',10000);
INSERT INTO stg_resource_use_in_community_cat(code, description, originator_id) VALUES('Not Reported','Not Reported',10000);
INSERT INTO stg_resource_use_in_community_cat(code, description, originator_id) VALUES('Other - for migration','Invalid',10000);

/* Install data for community_rights_cat
INSERT INTO stg_community_rights_cat(code, description, originator_id) VALUES('Full legal rights to all resources','Full legal rights to all resources',10000);
INSERT INTO stg_community_rights_cat(code, description, originator_id) VALUES('Legal rights to all resources, within certain constraints','e.g. legal regulations/limitations)',10000);
INSERT INTO stg_community_rights_cat(code, description, originator_id) VALUES('De facto rights to all resources','Full control of resources, although not in law',10000);
INSERT INTO stg_community_rights_cat(code, description, originator_id) VALUES('Temporal/ seasonal rights to resources','Temporal/ seasonal rights to resources',10000);
INSERT INTO stg_community_rights_cat(code, description, originator_id) VALUES('Rights to only certain resources/ a set amount','Rights to only certain resources/ a set amount',10000);
INSERT INTO stg_community_rights_cat(code, description, originator_id) VALUES('Rights to commercial use of the resources','Rights to commercial use of the resources',10000);
INSERT INTO stg_community_rights_cat(code, description, originator_id) VALUES('Protection of resources only: no use allowed','Protection of resources only: no use allowed',10000);
INSERT INTO stg_community_rights_cat(code, description, originator_id) VALUES('Not Reported','Not Reported',10000);
INSERT INTO stg_community_rights_cat(code, description, originator_id) VALUES('Other','Further description needed',10000);

/* Install data for equal_access_cat
INSERT INTO stg_equal_access_cat(code, description, originator_id) VALUES('Yes','Yes',10000);
INSERT INTO stg_equal_access_cat(code, description, originator_id) VALUES('No','No',10000);
INSERT INTO stg_equal_access_cat(code, description, originator_id) VALUES('Not Reported','Not Reported',10000);

/* Install data for icca_providers_cat
INSERT INTO stg_icca_providers_cat(code, description, originator_id) VALUES('Member of the community/ indigenous people','Member of the community/ indigenous people',10000);
INSERT INTO stg_icca_providers_cat(code, description, originator_id) VALUES('Representative/ associate of the community/ indigenous people','Representative/ associate of the community/ indigenous people',10000);
INSERT INTO stg_icca_providers_cat(code, description, originator_id) VALUES('Representative of an NGO (Non-Government Organisation)','Representative of an NGO (Non-Government Organisation)',10000);
INSERT INTO stg_icca_providers_cat(code, description, originator_id) VALUES('Representative of a governmental institution','Representative of a governmental institution',10000);
INSERT INTO stg_icca_providers_cat(code, description, originator_id) VALUES('Other','Further description needed',10000);

/* Install data for opportunities_status_cat
INSERT INTO stg_opportunities_status_cat(code, description, originator_id) VALUES('Strengthening','Strengthening',10000);
INSERT INTO stg_opportunities_status_cat(code, description, originator_id) VALUES('Weakening','Weakening',10000);
INSERT INTO stg_opportunities_status_cat(code, description, originator_id) VALUES('Stable','Stable',10000);
INSERT INTO stg_opportunities_status_cat(code, description, originator_id) VALUES('Not Applicable','Not Applicable',10000);
INSERT INTO stg_opportunities_status_cat(code, description, originator_id) VALUES('Not Reported','Not Reported',10000);
INSERT INTO stg_opportunities_status_cat(code, description, originator_id) VALUES('','',10000);

/* Install data for threats_cat
INSERT INTO stg_threats_cat(code, description, originator_id) VALUES('Decline in quality or quantity of biodiversity or nature','e.g. clean water and air, healthy soil',10000);
INSERT INTO stg_threats_cat(code, description, originator_id) VALUES('Negative impacts of tourism','Negative impacts of tourism',10000);
INSERT INTO stg_threats_cat(code, description, originator_id) VALUES('National laws, policies or practices','National laws, policies or practices',10000);
INSERT INTO stg_threats_cat(code, description, originator_id) VALUES('Other protected areas overlapping','Other protected areas overlapping',10000);
INSERT INTO stg_threats_cat(code, description, originator_id) VALUES('Unwanted development pressures','Unwanted development pressures',10000);
INSERT INTO stg_threats_cat(code, description, originator_id) VALUES('Extraction','e.g. hunting, mining, logging or fishing',10000);
INSERT INTO stg_threats_cat(code, description, originator_id) VALUES('Climate change','e.g. rapidly changing temperature and precipitation patterns, sea level rise, extreme weather events',10000);
INSERT INTO stg_threats_cat(code, description, originator_id) VALUES('Invasive or non-native species','Invasive or non-native species',10000);
INSERT INTO stg_threats_cat(code, description, originator_id) VALUES('Over-harvesting','Specify if from within or outside the community',10000);
INSERT INTO stg_threats_cat(code, description, originator_id) VALUES('Inappropriate management','e.g. management approaches or practices that are detrimental to the ICCA’s biodiversity or other values',10000);
INSERT INTO stg_threats_cat(code, description, originator_id) VALUES('De-legitimisation of customary rights','De-legitimisation of customary rights',10000);
INSERT INTO stg_threats_cat(code, description, originator_id) VALUES('Inequities (social, economic and/or political) within the ICCA','Inequities (social, economic and/or political) within the ICCA',10000);
INSERT INTO stg_threats_cat(code, description, originator_id) VALUES('Conflict with other communities','Conflict with other communities',10000);
INSERT INTO stg_threats_cat(code, description, originator_id) VALUES('Cultural change and/or loss of knowledge','Cultural change and/or loss of knowledge',10000);
INSERT INTO stg_threats_cat(code, description, originator_id) VALUES('Lack of recognition, or inappropriate forms of recognition, by governmental agencies, conservation organisations or others','Lack of recognition, or inappropriate forms of recognition, by governmental agencies, conservation organisations or others',10000);
INSERT INTO stg_threats_cat(code, description, originator_id) VALUES('Land ownership or tenure issues','Land ownership or tenure issues',10000);
INSERT INTO stg_threats_cat(code, description, originator_id) VALUES('Not Reported','Not Reported',10000);
INSERT INTO stg_threats_cat(code, description, originator_id) VALUES('Other','Further description needed',10000);

/* Install data for support_needed_cat
INSERT into stg_support_needed_cat(code, description, originator_id) VALUES('Political empowerment','Political empowerment',10000);
INSERT into stg_support_needed_cat(code, description, originator_id) VALUES('Cultural or social empowerment','Cultural or social empowerment',10000);
INSERT into stg_support_needed_cat(code, description, originator_id) VALUES('Appropriate recognition (legal or otherwise) from state authorities and/or other organisations','Appropriate recognition (legal or otherwise) from state authorities and/or other organisations',10000);
INSERT into stg_support_needed_cat(code, description, originator_id) VALUES('Health services','Health services',10000);
INSERT into stg_support_needed_cat(code, description, originator_id) VALUES('Education services','Education services',10000);
INSERT into stg_support_needed_cat(code, description, originator_id) VALUES('Equipment','e.g. GIS software, cameras, video recorders, computers',10000);
INSERT into stg_support_needed_cat(code, description, originator_id) VALUES('Technical capacity-building','IT, analytical or problem-solving skills, management plan guidance',10000);
INSERT into stg_support_needed_cat(code, description, originator_id) VALUES('Legal support','e.g. to file claims or resist external projects through litigation',10000);
INSERT into stg_support_needed_cat(code, description, originator_id) VALUES('Enhanced organisational/ internal capacity','Enhanced organisational/ internal capacity',10000);
INSERT into stg_support_needed_cat(code, description, originator_id) VALUES('Partnerships for self-determined development initiatives and sustainable livelihoods','Partnerships for self-determined development initiatives and sustainable livelihoods',10000);
INSERT into stg_support_needed_cat(code, description, originator_id) VALUES('Collaboration or communication with other ICCAs','Collaboration or communication with other ICCAs',10000);
INSERT into stg_support_needed_cat(code, description, originator_id) VALUES('Financial assistance','Financial assistance',10000);
INSERT into stg_support_needed_cat(code, description, originator_id) VALUES('Other','Further description needed',10000);
INSERT into stg_support_needed_cat(code, description, originator_id) VALUES('Not reported','Not reported',10000);

/* Install data for protected_planet_status_cat
INSERT INTO stg_protected_planet_status_cat(code, description, originator_id) VALUES('Designated','The ICCA has been legally recognised or dedicated by the state as a protected area or OECM (e.g. a Communal Conservancy)',10000);
INSERT INTO stg_protected_planet_status_cat(code, description, originator_id) VALUES('Established','The ICCA has not been legally designated or proposed by the state, but has been recognised or dedicated through other effective means, e.g. customary law, even if the ICCA overlaps with a legally designated site by the state (e.g. a National Park)',10000);
INSERT INTO stg_protected_planet_status_cat(code, description, originator_id) VALUES('Proposed','The protected area or OECM is in the process of being legally/formally designated',10000);
INSERT INTO stg_protected_planet_status_cat(code, description, originator_id) VALUES('Not Reported','Not Reported',10000);
INSERT INTO stg_protected_planet_status_cat(code, description, originator_id) VALUES('Not Applicable','Not Applicable',10000);
INSERT INTO stg_protected_planet_status_cat(code, description, originator_id) VALUES('Other - for migration','Invalid',10000);

/* Install data for scope_cat
INSERT INTO stg_scope_cat(code,description, originator_id) VALUES('None','None',10000);
INSERT INTO stg_scope_cat(code,description, originator_id) VALUES('Not for use by or on behalf of a commercial entity','Not for use by or on behalf of a commercial entity',10000);
INSERT INTO stg_scope_cat(code,description, originator_id) VALUES('Not for sharing beyond the managers of the ICCA Registry/Protected Planet','Not for sharing beyond the managers of the ICCA Registry/Protected Planet',10000);

/* Install data for submission_status_cat
INSERT INTO stg_submission_status_cat(code, description, originator_id) VALUES('1','ICCA Registry',10000);
INSERT INTO stg_submission_status_cat(code, description, originator_id) VALUES('2','ICCA Registry and Protected Planet',10000);



