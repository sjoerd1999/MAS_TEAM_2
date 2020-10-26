// Has the floorplan data
// Displays the floorplan

class Environment {
  int H, W;                // How many squares by how many squares is the grid?
  int SZ = 6;              // How many pixels is each square?
  ArrayList<Room> rooms = new ArrayList<Room>();
  boolean[][] data;
  boolean[][] isInside;    // Whether or not a square is inside or outside a building
  PShape walls = createShape(GROUP);
  PShape floor = createShape(GROUP);
  PVector[] exits = {new PVector(229, 190), new PVector(132, 118), new PVector(127, 219)};

  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //---------------------------------------LOAD IN DATA FROM TXT'S-------------------------------------------//
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////

  Environment() {
    String[] gridRaw = loadStrings("horst_full.txt");

    H = gridRaw.length;
    W = gridRaw[0].length();
    data = new boolean[H][W];

    // Load wall data from txt
    for (int y = 0; y < H; y++) for (int x = 0; x < W; x++) data[y][x] = gridRaw[y].charAt(x) == 'x';

    // Add rooms from txt
    String[] roomsRaw = loadStrings("HorstRooms.txt");
    String label = "";
    for (int i = 0; i < roomsRaw.length; i++) {
      if (roomsRaw[i].charAt(0) == '/') label =  roomsRaw[i];
      else {
        String[] splt = split(roomsRaw[i], " ");
        rooms.add(new Room(Integer.parseInt(splt[0]), Integer.parseInt(splt[1]), Integer.parseInt(splt[2]), Integer.parseInt(splt[3]), label));
      }
    }

    checkFloors();
  }

  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //-----------------------------------------GETTERS AND SETTERS---------------------------------------------//
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////

  boolean get(int x, int y) { // Returns whether a square is a wall or not
    if (x >= 0 && x < W && y >= 0 && y < H) return data[y][x];
    else return true;
  }

  PVector getRandomTarget() {
    int x = floor(random(1, grid.W-1));
    int y = floor(random(1, grid.H-1));
    while (this.get(x, y)) {
      x = floor(random(1, grid.W-1));
      y = floor(random(1, grid.H-1));
    }
    return new PVector(x, y);
  }

  PVector getClosestExit(PVector p) {
    float recordDist = 100000;
    PVector recordPos = new PVector(0, 0);
    for (PVector v : exits) if (PVector.dist(v, p) < recordDist) {
      recordPos.set(v);
      recordDist = PVector.dist(v, p);
    }
    return recordPos.mult(SZ);
  }

  void resetTables() {
    for (Room r : grid.rooms) r.numPersons = 0;
  }

  PVector getTable() {
    int roomN = floor(random(grid.rooms.size()));
    while (grid.rooms.get(roomN).numPersons >= grid.rooms.get(roomN).tables.size()) roomN = floor(random(grid.rooms.size()));
    return grid.rooms.get(roomN).getTable();
  }

  int getMaxAgents() { // How many agents can fit in the rooms in total
    int tot = 0;
    for (Room r : rooms) tot += r.tables.size();
    return tot;
  }

  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //--------------------------------------DISPLAYING THE FLOORPLAN-------------------------------------------//
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////

  void display() {
    // Display the floor/base
    shape(floor, 0, 0);

    // Display the rooms and tables
    for (Room r : rooms) r.display();

    // Display walls
    fill(200, 200, 220);
    for (int y = 0; y < H; y++) {
      int len = 0;
      for (int x = 0; x <= W; x++) {
        if (x < W && this.get(x, y)) len++;
        else {
          if (len > 1) {
            pushMatrix();
            translate(SZ / 2 + SZ * (x-0.5-len/2.0), SZ / 2 + SZ * y, 10);
            box(SZ*len, SZ, 25);
            popMatrix();
          }
          len = 0;
        }
      }
    }
    for (int x = 0; x <= W-1; x++) {
      int len = 0;
      for (int y = 0; y <= H; y++) {
        if (y < H && this.get(x, y)) len++;
        else {
          if (len > 1) {
            pushMatrix();
            translate(SZ / 2 + SZ * x, SZ / 2 + SZ * (y-0.5-len/2.0), 10);
            box(SZ, SZ*len, 25);
            popMatrix();
          }
          len = 0;
        }
      }
    }
  }

  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //---------------FUNCTIONS FOR DETERMINING WHICH SQUARE IS INSIDE OR OUTSIDE THE BUILDING------------------//
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////

  void checkFloors() {
    isInside = new boolean[H][W]; // Whether or not a square is inside or outside a building

    String[] insideRaw = loadStrings("HorstInsides.txt");
    for (String s : insideRaw) {
      String[] splt_raw = split(s, " ");
      int[] splt = {Integer.parseInt(splt_raw[0]), Integer.parseInt(splt_raw[1]), Integer.parseInt(splt_raw[2]), Integer.parseInt(splt_raw[3])};
      PShape ps = createShape(RECT, abs(splt[0] - splt[2]) / 2.0 + min(splt[0], splt[2]), abs(splt[1] - splt[3]) / 2.0 + min(splt[1], splt[3]), abs(splt[0] - splt[2])+1, abs(splt[1] - splt[3])+1);
      floor.addChild(ps);
    }
    floor.setFill(color(120, 120, 140));
    floor.setStroke(false);
    floor.scale(SZ);

    ArrayList<FloorCheck> fc = new ArrayList<FloorCheck>();
    fc.add(new FloorCheck(1, 190));
    fc.add(new FloorCheck(175, 325));
    fc.add(new FloorCheck(315, 325));
    fc.add(new FloorCheck(325, 150));
    fc.add(new FloorCheck(255, 390));

    for (int i = 0; i < 1000; i++) {
      for (int j = 0; j < fc.size(); j++) fc.get(j).run(fc);
    }
  }

  boolean isFloor(int x, int y) {
    if (x < 0 || y < 0 || x > W-1 || y > H-1) return true;
    else return isInside[y][x];
  }

  class FloorCheck {
    int x, y;
    boolean done;

    FloorCheck(int x_, int y_) {
      this.x=x_;
      this.y=y_;
      this.done=false;
    }

    void run(ArrayList<FloorCheck> walkers) {
      this.done=true;
      if (!get(this.x+1, this.y) && !isFloor(this.x+1, this.y)) {
        isInside[this.y][this.x+1] = true;//r
        walkers.add( new FloorCheck(this.x+1, this.y));
      }
      if (!get(this.x-1, this.y) && !isFloor(this.x-1, this.y)) {
        isInside[this.y][this.x-1] = true;//r
        walkers.add(new FloorCheck(this.x-1, this.y));
      }
      if (!get(this.x, this.y+1)&& !isFloor(this.x, this.y+1)) {
        isInside[this.y+1][this.x] = true;//u
        walkers.add( new FloorCheck(this.x, this.y+1));
      }
      if (!get(this.x, this.y-1)&& !isFloor(this.x, this.y-1)) {
        isInside[this.y-1][this.x] = true;//d
        walkers.add(new FloorCheck(this.x, this.y-1));
      }
    }
  }
}
