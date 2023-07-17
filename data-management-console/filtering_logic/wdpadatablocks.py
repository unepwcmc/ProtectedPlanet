from filtering_logic.blockregistry import BlockRegistry
from filtering_logic.datablock import DataBlock
from filtering_logic.postgresstreamer import PostgresStreamer


class ISODataBlock(DataBlock):

    def __init__(self):
        super().__init__("iso3")
        self.stream = None

    def forward_keys(self):
        return ["iso3.id"]

    def backward_keys(self):
        return ["wdpa_iso3_assoc.wdpa_id", "wdpa_iso3_assoc.parcel_id"]

    def streamer(self):
        self.stream = PostgresStreamer()
        self.stream.configure_base_sql(
            self.forward_keys(), self.backward_keys(),
            ["iso3", "wdpa_iso3_assoc"],
            ["iso3.id = wdpa_iso3_assoc.iso3_id"]
        )
        return self.stream


class WDPADataBlock(DataBlock):

    def __init__(self):
        super().__init__("wdpa_combined")
        self.stream = None

    def forward_keys(self):
        return ["wdpa.wdpa_id", "wdpa.parcel_id"]

    def backward_keys(self):
        return ["wdpa.wdpa_id"]

    def streamer(self):
        self.stream = PostgresStreamer()
        self.stream.configure_base_sql(
            self.forward_keys(), self.backward_keys(),
            ["wdpa", "spatial_data"],
            ["wdpa.wdpa_id = spatial_data.wdpa_id and wdpa.parcel_id = spatial_data.parcel_id"]
        )
        return self.stream


class PAMEDataBlock(DataBlock):

    def __init__(self):
        super().__init__("pame")
        self.stream = None

    def forward_keys(self):
        return ["pame.wdpa_id"]

    def backward_keys(self):
        return self.forward_keys()

    def streamer(self):
        self.stream = PostgresStreamer()
        self.stream.configure_base_sql(
            self.forward_keys(), self.backward_keys(),
            ["pame"],
            []
        )
        return self.stream


class GreenListDataBlock(DataBlock):

    def __init__(self):
        super().__init__("green_list")
        self.stream = None

    def forward_keys(self):
        return ["green_list.wdpa_id"]

    def backward_keys(self):
        return self.forward_keys()

    def streamer(self):
        self.stream = PostgresStreamer()
        self.stream.configure_base_sql(
            self.forward_keys(), self.backward_keys(),
            ["green_list"],
            []
        )
        return self.stream

class ReferenceDataBlock(DataBlock):

    def __init__(self, name):
        super().__init__(name)
        self.stream = None

    def forward_keys(self):
        val = self.name() + ".id"
        return [val]

    def backward_keys(self):
        val = self.name() + ".id"
        return [val]


    def streamer(self):
        self.stream = PostgresStreamer()
        self.stream.configure_base_sql(
            self.forward_keys(), self.backward_keys(),
            [self.name()],
            []
        )
        return self.stream

BlockRegistry.add_block("iso3", ISODataBlock())
BlockRegistry.add_block("wdpa", WDPADataBlock())
BlockRegistry.add_block("spatial_data", "wdpa")
BlockRegistry.add_block("pame", PAMEDataBlock())
BlockRegistry.add_block("green_list", GreenListDataBlock())
BlockRegistry.add_block("iucn_cat", ReferenceDataBlock("iucn_cat"))
BlockRegistry.add_block("no_take", ReferenceDataBlock("no_take"))
BlockRegistry.add_block("designation_status", ReferenceDataBlock("designation_status"))
BlockRegistry.add_block("orig_designation_status", ReferenceDataBlock("orig_designation_status"))
BlockRegistry.add_block("international_criteria", ReferenceDataBlock("international_criteria"))
BlockRegistry.add_block("data_providers", ReferenceDataBlock("data_providers"))
