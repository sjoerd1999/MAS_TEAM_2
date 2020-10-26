/*
TO DO:
 MOVEMENT:
 - Finish 'keep on the right side' movement (still a bit buggy when close to door openings)
 Lunch? Bathroom? Coffeebreaks? (no priority)
 
 COVID:
 - Get and implement covid19-specific paramenters/behaviour
 - Infection rate = 1 / dist(agent1, agent2) * timestep (something like this)
 - Quarantine infected cases?
 
 VISUALIZATION:
 - Show more readable graphs (with labels)
 
 AGENTS:
 - Add teacher agent
 
 Probs a lot more to add...
 */

// Press spacebar to spawn agents
// Press 'm' to start moving them

import peasy.*;
PeasyCam cam;

Environment grid;
ControlPanel controlPanel;
Time time;
ArrayList<Agent> agents = new ArrayList<Agent>();
ArrayList<Agent>[][] agentsGrid = new ArrayList[8][8];

int aniFrames = 9;              // Make this lower to improve startup time. Less frames in the animation = faster boot (1, 9 and 18 work well)
PShape[] human = new PShape[3]; // Human walking 3D models. [0] = susceptible, [1] = infected, [2] = recovered

String[] measures = {"Mask", "SocialDistance"};
float deltaT = 1 / 10.00;        // Timestep, keep smaller than <1/5 for reasonably accurate performance

void setup() {
  size(1500, 1000, P3D);
  //fullScreen(P3D);

  rectMode(CENTER);
  textAlign(CENTER, CENTER);

  grid= new Environment();
  controlPanel = new ControlPanel();
  cam = new PeasyCam(this, 1000);
  time = new Time();
  loadModels();
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//------------------------------------------LOAD IN 3D MODELS----------------------------------------------//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

void loadModels() {
  // Colors for the 3 states; susceptible, infected, recovered
  color[] colors = {color(72, 255, 100), color(255, 100, 100), color(72, 184, 232)};

  // Load 3d model data for the human visualization
  for (int s = 0; s < 3; s++) {
    human[s] = createShape(GROUP);
    for (int i = 0; i< aniFrames; i++) {
      PShape load = loadShape("3Dmodels/wlk" + (1 + i * (36 / aniFrames)) + ".obj");
      load.setFill(colors[s]);
      load.translate(0, 0, -i*8.45 * (18.00 / aniFrames));
      human[s].addChild(load);
    }
    PShape sit = loadShape("3Dmodels/sit.obj");
    sit.scale(0.1);
    sit.translate(0, -3.5);
    sit.setFill(colors[s]);
    human[s].addName("SIT", sit);
    human[s].scale(0.1);
  }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//----------------------------------------------MAIN LOOP--------------------------------------------------//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

void draw() {
  applyLights();
  translate(-grid.W*grid.SZ/4, -grid.H*grid.SZ/4);
  scale(0.5);
  surface.setTitle("FPS: " + frameRate);

  // Run the simulation for a couple of iterations each frame, depending on the set simulationspeed
  for (int iteration = 0; iteration < controlPanel.simulationSpeed; iteration++) {
    for (Agent a : agents) {
      a.run();
    }

    // Checking every agent with each other agents is really slow (n^n).
    // Thus split up the environment into a x-by-x grid of tiles and put each agent in the tile where it's in atm.
    // Then only check each agent with agents in the same tile. Tiles overlap a bit so to not miss any interactions
    if (time.stepCount % 10 == 0) { // Agents are not likely to switch tiles very frequently, so only check every x steps
      for (int x = 0; x < agentsGrid[0].length; x++) for (int y = 0; y < agentsGrid.length; y++) agentsGrid[y][x] = new ArrayList<Agent>();
      for (Agent a : agents) {
        if (a.isInside()) {
          int x_ = floor(a.gridPos.x / (grid.W * 1.00) * (agentsGrid[0].length * 1.00));
          int y_ = floor(a.gridPos.y / (grid.H * 1.00) * (agentsGrid.length * 1.00));
          agentsGrid[y_][x_].add(a);
        }
      }
    }

    for (int x = 0; x < agentsGrid[0].length; x++) for (int y = 0; y < agentsGrid.length; y++)
      for (int i = 0; i < agentsGrid[y][x].size(); i++) {
        for (int j = i + 1; j < agentsGrid[y][x].size(); j++) {
          if (i != j) {
            agentsGrid[y][x].get(i).interactions(agentsGrid[y][x].get(j));
          }
        }
      }

    controlPanel.update();
    time.update();
  }

  // Visualize!
  for (Agent a : agents) {
    a.show();
    //a.showTarget();
  }
  grid.display();
  controlPanel.display();
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------APPLY FANCY LIGHTING--------------------------------------------//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


void applyLights() {
  lights();
  background(100, 120, 120);  

  PVector camPos = new PVector(cam.getPosition()[0],cam.getPosition()[1],cam.getPosition()[2]);
  float dst = camPos.mag();
  pointLight(100, 0, 255, -dst, dst, dst);
  pointLight(0, 0, 255, dst, 0, -dst);
  pointLight(0, 255, 0, dst, -dst, dst);
  pointLight(255, 255, 0, -dst, 0, -dst);
  directionalLight(40, 80, 100, 0, -1, 0);

  noStroke();
  fill(100, 100, 170, 180);
  sphere(dst + 200);
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//--------------------------------------------EVENT HANDLING-----------------------------------------------//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


void keyPressed() {
  if (key == ' ') {
    // Add some agents in the grid at random locations
    for(int i = 0; i < 500; i++) agents.add(new Agent(new PVector(0,0), measures[0]));
    //for (int y = 0; y < grid.H; y++) {
    //  for (int x = 0; x < grid.W; x++) {
    //    if (!grid.get(x, y) && random(10) < 0.01 && agents.size() < grid.getMaxAgents() && !grid.isInside[y][x]) {
    //      agents.add(new Agent(new PVector(random((grid.SZ * x), (grid.SZ * x) + grid.SZ), random((grid.SZ * y), (grid.SZ * y) + grid.SZ)), measures[0]));
    //    }
    //  }
    //}
  }

  if (key == 'm') {
    println("YEET");
    for (Room r : grid.rooms) r.numPersons = 0;
    for (Agent a : agents) {
      //a.setTargetRandom();
      int roomN = floor(random(grid.rooms.size()));
      while (grid.rooms.get(roomN).numPersons >= grid.rooms.get(roomN).tables.size()) roomN = floor(random(grid.rooms.size()));
      a.setTarget(grid.rooms.get(roomN).getTable());
    }
  }
}

void mousePressed() {
  controlPanel.mousePressed();
}

void mouseReleased() {
  controlPanel.mouseReleased();
}
