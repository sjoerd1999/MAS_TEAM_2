// Used for the pathfinder algoritm to generate a flow field

class Walker {
  int x, y;
  boolean done;

  Walker(int x_, int y_) {
    this.x=x_;
    this.y=y_;
    this.done=false;
  }

  void run(ArrayList<Walker> walkers, PathFinder pf) {
    this.done=true;
    if (pf.checkGrid(this.x+1, this.y)) {
      pf.navGrid[this.y][this.x+1] = "l";//r
      walkers.add( new Walker(this.x+1, this.y));
    }
    if (pf.checkGrid(this.x-1, this.y)) {
      pf.navGrid[this.y][this.x-1] = "r";//r
      walkers.add(new Walker(this.x-1, this.y));
    }
    if (pf.checkGrid(this.x, this.y+1)) {
      pf.navGrid[this.y+1][this.x] = "u";//u
      walkers.add( new Walker(this.x, this.y+1));
    }
    if (pf.checkGrid(this.x, this.y-1)) {
      pf.navGrid[this.y-1][this.x] = "d";//d
      walkers.add(new Walker(this.x, this.y-1));
    }
  }
}
