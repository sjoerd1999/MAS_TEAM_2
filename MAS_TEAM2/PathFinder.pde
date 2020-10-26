class PathFinder {
  ArrayList<Walker> walkers = new ArrayList<Walker>();
  String[][] navGrid;
  boolean navUpdated = false;

  PathFinder() {
    navGrid = new String[grid.H][grid.W];
    resetNavGrid();
  }

  void run() {
    if (walkers.size() != 0) {
      navUpdated = false;
      for (int j=0; j<100; j++) {    
        for (int i=walkers.size()-1; i>=0; i--) {
          Walker w = walkers.get(i);
          if (!w.done) {
            w.run(walkers, this);
          } else {
            walkers.remove(i);
          }
        }
      }
    } else if(!navUpdated){
     //updateNav();
     navUpdated = true;
    }
  }

  boolean checkGrid(int x, int y) {
    if ((grid.get(x, y))||(!navGrid[y][x].equals("_"))) {
      return false;
    } else {
      return true;
    }
  }

  void resetNavGrid() {
    navGrid = new String[grid.H][grid.W];
    for (int y = 0; y < grid.H; y++) for (int x = 0; x < grid.W; x++) navGrid[y][x] = "_";
  }

  void setTarget(int x, int y) {
    walkers.clear();
    resetNavGrid();
    navGrid[y][x] = "X";
    walkers.add(new Walker(x, y));
  }

  void updateNav() {
    // Makes sure that the agents walk on the right. Implemented in such a way that they can't 'hug a wall' on their left.
    String[] dirs = {"u", "d", "l", "r"};
    String[] set = {"_", "d", "!_", "!_"};
    //String dir = "u";
    for (String dir : dirs) {
      set[1] = dir;
      boolean swap = (dir.equals("l") || dir.equals("r"));
      boolean rev = (dir.equals("d") || dir.equals("l"));

      for (int y = 1; y < grid.H-3; y += (swap ? 1 : 2)) {
        for (int x = 1; x < grid.W-3; x += (swap ? 2 : 1)) {
          boolean b = true;
          for (int i = 0; i < 3; i++) for (int j = 0; j < 2; j++) {
            if (!getNav(x + (swap ? j : i), y + (swap ? i : j), set[(rev ? 2-i : i)])) {
              b = false;
              break;
            }
          }

          if (b) {
            int i_ = (rev ? 0 : 2);
            navGrid[y + (swap ? 1 : 0)][x + (swap ? 0 : 1)] = pdir(dir);
            navGrid[y + 1][x + 1] = dir;
            navGrid[y + (swap ? i_ : 0)][x + (swap ? 0 : i_)] = dir;
            navGrid[y + (swap ? i_ : 1)][x + (swap ? 1 : i_)] = dir;

            int j_ = (rev ? -1 : 3);
            if (getNav(x + (swap ? 0 : j_), y + (swap ? j_ : 0), "!_") && getNav(x+(swap ? 1 : j_), y + (swap ? j_ : 1), "!_")) {
              navGrid[y + (swap ? j_ : 0)][x + (swap ? 0 : j_)] = dir;
              navGrid[y + (swap ? j_ : 1)][x + (swap ? 1 : j_)] = dir;
              navGrid[y + (swap ? i_ : 1)][x + (swap ? 1 : i_)] = pdir(dir);
            }
          }
        }
      }
    }
  }

  String pdir(String dir) {
    return(dir.equals("d") ? "l" : dir.equals("u") ? "r" : dir.equals("l") ? "u" : "d");
  }

  boolean getNav(int x, int y, String s) {
    if (s.equals("!_") && !navGrid[y][x].equals("_")) return true;
    if (navGrid[y][x].equals(s)) return true;
    return false;
  }
}
