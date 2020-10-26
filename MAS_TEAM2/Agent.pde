import java.util.Random;

class Agent {
  PathFinder pf;
  Random r = new Random();

  // Movement constants
  float maxVelocity = 14 * deltaT;                // In 10 * cm/s
  float speed = 4 * deltaT;
  float returnVelocity = 4 * deltaT;
  float loseVelocity = 1 + 0.35 * deltaT;

  // Movement position/velocity
  PVector pos = new PVector(0, 0);
  PVector vel = new PVector(0, 0);
  PVector gridPos = new PVector(0, 0);       // Position in grid
  PVector targetPos = new PVector(0, 0);

  // Walking animation
  float aniFrame = 0;

  // Basic Agent parameters
  int age = r.nextInt(25-18 + 1) + 18;    // between 18 and 25
  boolean wearsMask = false;
  int socialDistance = 5;                 // used in the avoid method
  boolean inside = false;
  String[] moveStates = {"INACTIVE", "WAITING", "MOVING", "ROOM"};
  String curMoveState = "INACTIVE";
  float nextActionTime = 0;
  boolean roomLock = false, leaving = false;

  // Covid-19 parameters
  String[] states = {"Susceptible", "Infected", "Recovered"};
  String currentState = states[0];        // Susceptible by default
  float transmissionProbability = 0.001;
  String measure = "";                    // currently employed covid measure

  Agent(PVector position_, String measure_) {
    double rnd = Math.random();
    if (rnd < 0.1)
      currentState = states[1];           // Randomly spawn infected individuals

    this.measure = measure_;
    if (measure.equals("Mask")) {
      if (rnd < 0.8)
        wearsMask = true;                 // Make some people wear a mask
    } else if (measure.equals("SocialDistance")) {
      socialDistance = 15;
    }

    pos = position_.copy();
    pf = new PathFinder();
  }



  void run() {
    //if (PVector.dist(pos, PVector.mult(targetPos, grid.SZ)) < 10 && random(10) < 0.05) setTargetRandom();
    switch(curMoveState) {
    case "INACTIVE":
      // DO NOTHING
      break;

    case "WAITING":
      // WAIT TO ENTER BUILDING
      if (nextActionTime < time.getTimeFloat()) {
        this.setTarget(grid.getTable()); // Set a table as the target position
        this.pos.set(grid.getClosestExit(this.targetPos)); // Spawn the agent at the entrance
        curMoveState = "MOVING";
      }
      break;

    case "MOVING":
      // MOVE TO A ROOM/EXIT
      move();
      recover();

      if (time.stepCount % 10 == 0) {
        if (PVector.dist(pos, PVector.mult(targetPos, grid.SZ)) < 3) { // Either close to a table or exit
          if (leaving) {
            curMoveState = "INACTIVE";
          } else {
            pos = PVector.mult(targetPos, grid.SZ);
            vel.setMag(0);
            curMoveState = "ROOM";
            roomLock = true;
          }
        }
      }

      // If target is close to entrance and pos is close to entrance, go to inactive
      break;

    case "ROOM":
      // STAY IN THE ROOM
      if (!roomLock && nextActionTime < time.getTimeFloat()) {
        curMoveState = "MOVING";
      }
      recover();
      break;
    }
  }



  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //-----------------------------------------GETTERS AND SETTERS---------------------------------------------//
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////

  void setTarget(PVector t) {
    pf.setTarget((int)t.x, (int)t.y);
    targetPos.set(t.x+0.5, t.y+0.5);
  }

  void setTargetRandom() {
    setTarget(grid.getRandomTarget());
  }

  String getCurrentState() {
    return this.currentState;
  }

  void setCurrentState(String s) {
    this.currentState = s;
  }

  boolean isInside() {
    return curMoveState.equals("MOVING") || curMoveState.equals("ROOM") || curMoveState.equals("LEAVING");
  }

  void setLecture(float wait) { // The roster says that the lecture starts in 0.x hours
    this.nextActionTime = time.getTimeFloat() + random(0, wait); // Wait a random amount before starting to move

    // Agent was not active, so make it enter the building after a short wait
    if (curMoveState.equals("INACTIVE")) curMoveState = "WAITING";

    // Agent was already moving somewhere, but will move to a new target instantly
    if (curMoveState.equals("MOVING") || curMoveState.equals("WATING") || curMoveState.equals("ROOM")) {
      this.setTarget(grid.getTable()); 
      roomLock = false;
    }

    leaving = false;
  }

  void setNoLecture(float wait) { // The roster says that the the agent does not have a lecture anymore
    this.nextActionTime = time.getTimeFloat() + random(0, wait); // Wait a random amount before starting to move

    // If the agent was waiting to enter, make him stop
    if (curMoveState.equals("WATING")) curMoveState = "INACTIVE";

    // Agent was already moving somewhere, but will move to a new target instantly
    if (curMoveState.equals("MOVING") || curMoveState.equals("ROOM")) {
      this.setTarget(PVector.div(grid.getClosestExit(PVector.div(pos, grid.SZ)), grid.SZ)); 
      roomLock = false;
    }
    leaving = true;
  }


  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //----------------------------------MOVING AROUND USING PATHFINDING----------------------------------------//
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////

  void move() {
    pf.run();

    String dir = pf.navGrid[int(gridPos.y)][int(gridPos.x)];
    float speed_ = speed;
    if (PVector.dist(pos, targetPos) < 30) speed_ = speed * (PVector.dist(pos, targetPos)/30.0);
    if (dir.equals("d")) vel.y+=speed_;
    else if (dir.equals("u")) vel.y-=speed_;
    else if (dir.equals("r")) vel.x+=speed_;
    else if (dir.equals("l")) vel.x-=speed_;

    if (vel.mag() > maxVelocity) vel.setMag(maxVelocity); // limit velocity

    // Wall avoidance
    pos.x+=vel.x;
    pos.x = constrain(pos.x, 0, grid.W*grid.SZ);
    gridPos.set(constrain(floor(pos.x/(grid.SZ*1.00)), 0, grid.W-1), constrain(floor(pos.y/(grid.SZ*1.00)), 0, grid.H-1));
    if (pf.navGrid[int(gridPos.y)][int(gridPos.x)].equals("_")) {
      if (vel.x>0) {
        vel.x*=-(returnVelocity+random(0.1, 0.3));
        pos.x=(gridPos.x*grid.SZ)-1;
      } else if (vel.x<0) {
        vel.x*=-(returnVelocity+random(0.1, 0.3));
        pos.x=(gridPos.x*grid.SZ)+grid.SZ+1;
      }
    }

    pos.y+=vel.y;
    pos.y = constrain(pos.y, 0, grid.H*grid.SZ);
    gridPos.set(constrain(floor(pos.x/(grid.SZ*1.00)), 0, grid.W-1), constrain(floor(pos.y/(grid.SZ*1.00)), 0, grid.H-1));
    if (pf.navGrid[int(gridPos.y)][int(gridPos.x)].equals("_")) {      
      if (vel.y>0) {
        vel.y *= -(returnVelocity +random(0.1, 0.3));
        pos.y = (gridPos.y * grid.SZ) - 1;
      } else if (vel.y<0) {
        vel.y *= -(returnVelocity + random(0.1, 0.3));
        pos.y = (gridPos.y * grid.SZ) + grid.SZ + 1;
      }
    }

    vel.div(loseVelocity);
    if (vel.mag() > maxVelocity) vel.setMag(maxVelocity); // limit velocity

    aniFrame+=vel.mag()*(aniFrames / 18.00)*1.1;
    if (floor(aniFrame) >= aniFrames || vel.mag() < 0.1) aniFrame = 0;
  }

  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //------------------------------------COVID19 INFECTING/RECOVERING-----------------------------------------//
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////


  void interactions(Agent a) {
    float dist = PVector.dist(a.pos, pos); // sqrts take quite some time to process, so only doing it once for both functions
    avoid(a, dist);
    infect(a, dist);

    // Also execute the interaction in the other agent
    a.avoid(this, dist);
    a.infect(this, dist);
  }

  void avoid(Agent a, float dist) {
    if (dist < this.socialDistance) {
      PVector force = PVector.sub(pos, a.pos);
      force.setMag(1/(dist+0.1) * 10 * deltaT);
      //float pforce = 1+constrain(PVector.dist(pos,PVector.mult(targetPos, 20))*0.01, 0, 1.0);
      //println(pforce);
      //force.mult(pforce);
      vel.add(force);
    }
  }

  // I can infect others if I am carrying the virus
  // Only infect Susceptible individuals -> enter Infected state
  void infect(Agent a, float dist) {
    if (dist < 30 && this.currentState.equals("Infected") && a.getCurrentState().equals("Susceptible")) {
      float a_ = 0.1, c_ = 0.1;
      //double rnd = Math.random();
      float rnd = random(0.0,1.0);
      this.transmissionProbability = a_* pow((float)Math.E, (-sq(dist/10.00)) / (2 * sq(c_)));
      if (rnd < this.transmissionProbability) {
        a.setCurrentState("Infected");
      }
    }
  }

  // recover from the infection very simple implementation
  void recover() {
    double rnd = Math.random();
    if (rnd < 0.001 && this.getCurrentState().equals("Infected"))
      this.setCurrentState("Recovered");
  }

  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //----------------------------------DISPLAYING THE AGENT AND TARGET----------------------------------------//
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////


  void show() {
    if (this.isInside()) {
      float angle = atan2(vel.y, vel.x);
      int state = (getCurrentState().equals("Infected") ? 1 : getCurrentState().equals("Recovered") ? 2 : 0);
      PShape humanObj = human[state].getChild(floor(aniFrame));
      if (PVector.dist(pos, PVector.mult(targetPos, grid.SZ)) < 3 || curMoveState.equals("ROOM")) {
        humanObj = human[state].getChild("SIT");
        angle = 0;
      }

      pushMatrix();
      translate(pos.x, pos.y);
      rotateX(HALF_PI);
      rotateY(angle+HALF_PI);
      shape(humanObj);
      popMatrix();
    }
  }

  void showTarget() {
    stroke(0, 40);
    strokeWeight(1);
    line(pos.x, pos.y, targetPos.x*grid.SZ, targetPos.y*grid.SZ);
    pushMatrix();
    translate(targetPos.x*grid.SZ, targetPos.y*grid.SZ);
    stroke(0, 100);
    line(-3, -3, 3, 3);
    line(3, -3, -3, 3);
    popMatrix();
    noStroke();
  }
}
