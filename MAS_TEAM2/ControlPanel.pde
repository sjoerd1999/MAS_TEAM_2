class ControlPanel {
  int[] simulationSpeeds = {1, 2, 5, 10, 100, 500};
  int simulationSpeed = 1;
  ArrayList<Integer> infectedHistory = new ArrayList<Integer>();
  ArrayList<Integer> recoveredHistory = new ArrayList<Integer>();

  boolean showRoomLabels = false;

  boolean show = false;
  float w = 350;

  // Item positions:
  float indent = 20;
  float sliderY = 80, sliderPos = indent;
  int sliderIndex = 0;
  boolean sliderStart = false;
  int toggleSize = 40;
  float labelToggleX = w-indent-10;
  float labelToggleY = 20;
  float labelToggleSz = 25;
  boolean camActive = true;

  void display() {
    pushMatrix();
    camera();
    hint(DISABLE_DEPTH_TEST);
    noLights();

    if (show) {
      displayControls();
      displayGraph();
    }
    displayToggle();

    if (show) {
      fill(255);
      noStroke();
      textSize(16);
      textAlign(LEFT);
      text("TOTAL AGENTS: " + agents.size(), indent, sliderY+300);
      text("INFECTED: " + getTotalInfected() + " (" + int(getTotalInfected() / (agents.size()*1.00)*100) + "%)", indent, sliderY+330);
      text("RECOVERED: " + getTotalRecovered() + " (" + int(getTotalRecovered() / (agents.size()*1.00)*100) + "%)", indent, sliderY+360);
      textAlign(CENTER, CENTER);
      text(time.getTimeString(), w/2, 15);
    }

    hint(ENABLE_DEPTH_TEST);

    popMatrix();
  }

  void displayToggle() {
    pushMatrix();
    if (show) translate(w, 0);
    fill(255, 100);
    stroke(255, 150);
    strokeWeight(4);
    rect(indent+toggleSize*0.5, indent+toggleSize*0.5, toggleSize, toggleSize, 5);
    if (show) {
      line(indent+toggleSize*0.8, indent+toggleSize*0.16, indent+toggleSize*0.2, indent+toggleSize*0.5);
      line(indent+toggleSize*0.8, indent+toggleSize*0.83, indent+toggleSize*0.2, indent+toggleSize*0.5);
    } else {
      line(indent+toggleSize*0.2, indent+toggleSize*0.16, indent+toggleSize*0.8, indent+toggleSize*0.5);
      line(indent+toggleSize*0.2, indent+toggleSize*0.83, indent+toggleSize*0.8, indent+toggleSize*0.5);
    }
    popMatrix();
  }

  void displayControls() {
    // Semi-transparent background
    fill(0, 50);
    rect(w/2, height/2, w, height);

    // FrameRate
    fill(255);
    textSize(16);
    textAlign(LEFT);
    text("FPS: " + nf(frameRate, 0, 1), indent, 20);

    // Speed-up slider
    fill(255);
    stroke(255);
    strokeWeight(1);
    textSize(18);
    textAlign(CENTER, CENTER);
    text("SIMULATION SPEED", w / 2, sliderY - 30);
    rect(indent+(w-indent*2)/2, sliderY, w-indent*2, 5);
    ellipse(sliderPos, sliderY, 15, 15);
    textSize(15);
    for (int i = 0; i < simulationSpeeds.length; i++) {
      rect(map(i, 0, simulationSpeeds.length - 1, indent, w - indent), sliderY, 4, 10);
      text(simulationSpeeds[i] + "x", map(i, 0, simulationSpeeds.length - 1, indent, w - indent), sliderY+20);
    }

    // LabelToggle
    noFill();
    stroke(255);
    strokeWeight(4);
    rect(labelToggleX, labelToggleY, labelToggleSz, labelToggleSz, 5);
    fill(255);
    textSize(14);
    text("L", labelToggleX, labelToggleY-2);
  }

  void displayGraph() {
    stroke(255);
    line(indent, sliderY+75, indent, sliderY+275);
    line(indent, sliderY+275, w-indent, sliderY+275);
    stroke(255, 150);
    strokeWeight(2);
    if (infectedHistory.size() > 10) {
      // Infected
      fill(255, 0, 0, 50);
      beginShape();
      vertex(indent, sliderY+275);
      for (int i = 0; i < 100; i++) {
        int index = floor(map(i, 0, 100, 0, infectedHistory.size()-1));
        float y = infectedHistory.get(index) / (agents.size() + 1.00) * 200.00;
        vertex(map(i, 0, 100, indent, w-indent), sliderY+275-y);
      }
      vertex(w-indent, sliderY+275);
      endShape(CLOSE);

      // Recovered
      fill(0, 0, 255, 20);
      beginShape();
      vertex(indent, sliderY+275);
      for (int i = 0; i < 100; i++) {
        int index = floor(map(i, 0, 100, 0, recoveredHistory.size()-1));
        float y = recoveredHistory.get(index) / (agents.size() + 1.00) * 200.00;
        vertex(map(i, 0, 100, indent, w-indent), sliderY+275-y);
      }
      vertex(w-indent, sliderY+275);
      endShape(CLOSE);
    }
  }

  int getTotalInfected() {
    int tot = 0;
    for (Agent a : agents) if (a.getCurrentState().equals("Infected")) tot++;
    return tot;
  }

  int getTotalRecovered() {
    int tot = 0;
    for (Agent a : agents) if (a.getCurrentState().equals("Recovered")) tot++;
    return tot;
  }

  void update() {
    // Disable the 3D peasy cam to be able to press the numpad control panel without everything moving
    if (mouseX < w && sliderStart && show && camActive) {
      camActive = false;
      cam.setActive(false);  //PeasyCam off
    } else if(!camActive){
      camActive = true;
      cam.setActive(true);  //PeasyCam on
    }
    if (sliderStart) sliderPos =constrain(mouseX, indent, w-indent);

    infectedHistory.add(getTotalInfected());
    recoveredHistory.add(getTotalRecovered());
  }

  void mousePressed() {
    if (show && abs(mouseX - (indent+(w-indent*2)/2)) < (w-20)/2 && abs(mouseY - sliderY) < 10) sliderStart = true;
    if (!show && abs(mouseX - (indent+toggleSize/2)) < toggleSize/2 && mouseY < indent+toggleSize) show = true;
    if (show && abs(mouseX - (w + indent+toggleSize/2)) < toggleSize/2 && mouseY < indent+toggleSize) show = false;
    if (show && abs(mouseX - (labelToggleX)) < labelToggleSz/2 && abs(mouseY - (labelToggleY)) < labelToggleSz/2) showRoomLabels = !showRoomLabels;
  }
  void mouseReleased() {
    if (sliderStart) {
      sliderIndex = round(map(mouseX, 20, w-indent, 0, simulationSpeeds.length-1));
      sliderIndex = constrain(sliderIndex, 0, simulationSpeeds.length -1);
      simulationSpeed = simulationSpeeds[sliderIndex];
      sliderPos = map(sliderIndex, 0, simulationSpeeds.length - 1, indent, w - indent);
    }
    sliderStart = false;
  }
}
