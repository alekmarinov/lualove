return {
  version = "1.2",
  luaversion = "5.1",
  tiledversion = "1.2.4",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 20,
  height = 20,
  tilewidth = 100,
  tileheight = 69,
  nextlayerid = 2,
  nextobjectid = 1,
  backgroundcolor = { 24, 206, 11 },
  properties = {},
  tilesets = {
    {
      name = "map-tile",
      firstgid = 1,
      tilewidth = 100,
      tileheight = 69,
      spacing = 0,
      margin = 0,
      columns = 4,
      image = "map-tile.png",
      imagewidth = 400,
      imageheight = 276,
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 100,
        height = 69
      },
      properties = {},
      terrains = {},
      tilecount = 16,
      tiles = {
        {
          id = 0,
          properties = {
            ["speed"] = "-80"
          }
        },
        {
          id = 1,
          properties = {
            ["speed"] = "-100"
          }
        },
        {
          id = 2,
          properties = {
            ["speed"] = "-100"
          }
        },
        {
          id = 3,
          properties = {
            ["speed"] = "-100"
          }
        },
        {
          id = 4,
          properties = {
            ["speed"] = "-100"
          }
        },
        {
          id = 5,
          properties = {
            ["speed"] = "-100"
          }
        },
        {
          id = 6,
          properties = {
            ["speed"] = "-100"
          }
        },
        {
          id = 7,
          properties = {
            ["speed"] = "-100"
          }
        },
        {
          id = 8,
          properties = {
            ["speed"] = "-100"
          }
        },
        {
          id = 9,
          properties = {
            ["speed"] = "-100"
          }
        },
        {
          id = 10,
          properties = {
            ["speed"] = "-100"
          }
        },
        {
          id = 11,
          properties = {
            ["speed"] = "0"
          }
        },
        {
          id = 12,
          properties = {
            ["speed"] = "0"
          }
        },
        {
          id = 14,
          properties = {
            ["speed"] = "0"
          }
        }
      }
    }
  },
  layers = {
    {
      type = "tilelayer",
      id = 1,
      name = "Ground",
      x = 0,
      y = 0,
      width = 20,
      height = 20,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "lua",
      data = {
        3, 4, 2, 5, 15, 1, 8, 6, 1, 15, 15, 4, 4, 3, 2, 5, 15, 15, 15, 15,
        4, 15, 15, 15, 15, 1, 15, 9, 1, 1, 15, 15, 15, 15, 2, 3, 5, 15, 15, 15,
        5, 15, 15, 15, 15, 1, 1, 9, 15, 1, 15, 15, 15, 15, 15, 2, 4, 3, 15, 15,
        5, 15, 2, 15, 15, 15, 1, 9, 15, 1, 15, 15, 15, 15, 15, 3, 4, 5, 5, 15,
        2, 15, 15, 15, 15, 15, 1, 9, 15, 1, 1, 15, 15, 15, 15, 15, 3, 2, 5, 4,
        5, 15, 15, 15, 15, 15, 1, 9, 15, 15, 1, 15, 1, 15, 15, 15, 15, 2, 2, 3,
        3, 15, 15, 4, 15, 15, 1, 8, 10, 10, 6, 15, 1, 15, 15, 15, 15, 2, 3, 2,
        2, 15, 15, 15, 15, 15, 1, 15, 15, 15, 13, 15, 1, 1, 15, 2, 15, 15, 15, 5,
        2, 15, 15, 3, 4, 15, 15, 15, 11, 10, 7, 15, 1, 15, 15, 15, 15, 15, 15, 4,
        3, 2, 15, 15, 15, 15, 15, 1, 9, 15, 15, 1, 1, 15, 15, 15, 15, 15, 15, 2,
        2, 2, 15, 15, 15, 15, 15, 15, 9, 15, 15, 1, 1, 15, 3, 15, 15, 15, 15, 4,
        5, 4, 15, 15, 5, 15, 15, 15, 13, 15, 15, 15, 1, 15, 15, 1, 1, 15, 15, 2,
        4, 3, 15, 15, 15, 15, 15, 15, 8, 10, 12, 10, 10, 10, 10, 6, 1, 15, 15, 2,
        2, 3, 15, 15, 15, 15, 15, 1, 15, 15, 15, 15, 1, 1, 15, 9, 15, 1, 15, 4,
        5, 2, 3, 15, 15, 4, 15, 15, 15, 1, 15, 15, 15, 15, 15, 9, 15, 1, 15, 3,
        5, 2, 4, 15, 15, 15, 15, 15, 15, 15, 15, 11, 10, 12, 10, 7, 15, 15, 15, 3,
        15, 2, 5, 4, 15, 15, 15, 15, 1, 15, 15, 9, 15, 15, 15, 15, 1, 15, 15, 5,
        15, 2, 5, 5, 15, 15, 1, 15, 15, 15, 15, 9, 15, 1, 1, 15, 15, 15, 15, 2,
        15, 15, 2, 2, 15, 15, 1, 11, 10, 12, 10, 7, 1, 1, 1, 15, 15, 3, 3, 4,
        15, 15, 4, 4, 15, 15, 15, 9, 15, 15, 15, 15, 15, 15, 15, 15, 5, 4, 4, 2
      }
    }
  }
}
