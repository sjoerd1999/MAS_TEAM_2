// Keeps track of time in the simulation
// Also contains roster / time schedule information

class Time {
  float timer;                    // How many seconds (real life seconds) the simulation has been run, start at 8:45
  long stepCount;
  float[] lectureStartTimes = {9.0, 11.0, 13.75, 15.75};
  float[] lectureEndTimes = {10.75, 12.75, 15.5, 17.5};
  float enterDuration = 0.16;     // between 1 and 10 minutes before a lecture, people start entering the building to go to the lecture (uniform distribution)
  float leaveDuration = 0.08;     // between 0 and 5 minutes after a lecture, people start leaving the room to leave the building or go to the next lecture in the building (uniform distribution)
  boolean hasAnnounced = false;
  float nextLectureTime = 0;

  void update() {
    this.timer+=deltaT;
    this.stepCount++;
    if (stepCount % 10 == 1) { // Only check every 10 steps for faster performance
      float prevLectureTime = nextLectureTime;
      for (int i = 0; i < lectureStartTimes.length; i++) if (getTimeFloat() < lectureStartTimes[i]) {
        nextLectureTime = lectureStartTimes[i];
        break;
      }
      if (prevLectureTime != nextLectureTime) hasAnnounced = false;
      if (nextLectureTime - getTimeFloat() < enterDuration && !hasAnnounced) {
        announce();
        hasAnnounced = true;
      }
    }
  }

  void announce() {
    println("NEXT LECTURE STARTS SOON!");
    grid.resetTables();
    for (Agent a : agents) {
      if (random(10) < 5) a.setLecture(enterDuration);
      else a.setNoLecture(leaveDuration);
    }
  }

  String getTimeString() { // Returns e.g. "00:34:59"
    return nf(this.getHours(), 2, 0) + ":" + nf(this.getMinutes(), 2, 0) + ":" + nf(this.getSeconds(), 2, 0);
  }

  float getTimeFloat() { // 9:45 = 9.75
    return this.timer/3600.00 + 8;
  }

  long getHours() {
    return floor(this.timer/3600.00) % 24 + 8;
  }

  long getMinutes() {
    return floor(this.timer/60.00) % 60;
  }

  long getSeconds() {
    return int(this.timer) % 60;
  }
}
