# A constant to translate between SITE ID and the path for the green list image for that WDPA (located within the green_list directory within images)
# We're using the translation approach below as we don't want to store the images in the protected_area model in the database and there are only a few green list sites.

# All images are cropped to 600px * 400px

GREEN_LIST_IMAGES = {
  309970 => "arakwal.jpg",
  315645 => "changqing.jpg",
  349268 => "doananationalpark.jpg",
  95573 => "east_dongting_lake.jpg",
  555555490 => "grevys_zebras_in_lewa.jpg",
  95996 => "longwanqun.jpg",
  63136 => "montague_island.jpg",
  26654 => "mt_guang_shan.jpg",
  555566900 => "ol_pejeta_black_rhinos.jpg",
  349467 => "sierra_nevada_national_park.jpg",
  95693 => "tangjiahe.jpg",
  95464 => "wudalianchi.jpg"
}
