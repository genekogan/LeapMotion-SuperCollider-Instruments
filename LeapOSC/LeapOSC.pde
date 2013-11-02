import com.onformative.leap.LeapMotionP5;
import com.leapmotion.leap.*;
import com.leapmotion.leap.Gesture.*;
import oscP5.*;
import netP5.*;

// PARAMETERS

// which data to send OSC
boolean OSC_HAND = true;
boolean OSC_HAND_AXIS = true;
boolean OSC_FINGERS = true;
boolean OSC_HAND_SIZE = true;
boolean OSC_HAND_SIZE_TRIGGER = true;

// if sending hand trigger, bounding sizes
float HAND_THRESH_MIN = 0.15;
float HAND_THRESH_MAX = 0.45;

LeapMotionP5 leap;
OscP5 oscP5;
NetAddress myRemoteLocation;
float[] handSize;
boolean[] handThresh = new boolean[]{false, false};
int[] alph = new int[]{0, 0};
PVector viewAngle = new PVector();
PVector[] handPosition = new PVector[2]; 
float SIZE_BOX = 400;

void setup() {
  size(900, 680, P3D);
  frameRate(60);
  oscP5 = new OscP5(this, 12000);
  myRemoteLocation = new NetAddress("127.0.0.1", 57120);

  // setup leap + osc
  leap = new LeapMotionP5(this);
  oscP5 = new OscP5(this, 12000);
  myRemoteLocation = new NetAddress("127.0.0.1", 57120);
  
  // enable gestures
  leap.enableGesture(Type.TYPE_SWIPE);
}

void draw() 
{
  background(255); 
  pushMatrix();

  // draw finger box frame  
  noFill();
  stroke(0, 150);
  translate((width-100)/2, height/2, 0);
  rotateX(viewAngle.y);
  rotateY(viewAngle.x);
  box(SIZE_BOX);

  // get leap data on hands/fingers
  handSize = new float[]{0, 0};
  ArrayList<Hand> hands = leap.getHandList();
  for (int h=0; h<min(hands.size(),2); h++) {
    Hand hand = hands.get(h);

    // get wrist rotations
    float pitch = radians(leap.getPitch(hand));
    float roll = radians(leap.getRoll(hand));
    float yaw = radians(leap.getYaw(hand));

    // get hand statistics    
    handPosition[h] = leap.getPosition(hand);
    float handRadius = leap.getSphereRadius(hand);
    handPosition[h].set(
        constrain(map(handPosition[h].x, -100, 600, 0, 1), 0, 1),
        constrain(map(handPosition[h].y,  600,   0, 0, 1), 0, 1),
        constrain(map(handPosition[h].z, -600, 600, 0, 1), 0, 1)); 
    if (OSC_HAND)
      sendOSCMessage("/h"+(h+1)+"/", new float[]{handPosition[h].x, handPosition[h].y, handPosition[h].z});
    if (OSC_HAND_AXIS)
      sendOSCMessage("/h"+(h+1)+"axis/", new float[]{pitch, roll, yaw});
    
    // get finger positions and bounding box
    ArrayList<Finger> fingers = leap.getFingerList(hand);
    PVector minFinger = new PVector(1,1,1);
    PVector maxFinger = new PVector(0,0,0);
    PVector[] fingerPos = new PVector[fingers.size()];
    for (int f=0; f<fingers.size(); f++) {
      Finger finger = fingers.get(f);
      fingerPos[f] = leap.getTip(finger);
      fingerPos[f].set(
        constrain(map(fingerPos[f].x, -100, 600, 0, 1), 0, 1),
        constrain(map(fingerPos[f].y,  600,   0, 0, 1), 0, 1),
        constrain(map(fingerPos[f].z, -600, 600, 0, 1), 0, 1)); 
      if (fingerPos[f].x > maxFinger.x)  maxFinger.x = fingerPos[f].x;
      if (fingerPos[f].x < minFinger.x)  minFinger.x = fingerPos[f].x;
      if (fingerPos[f].y > maxFinger.y)  maxFinger.y = fingerPos[f].y;
      if (fingerPos[f].y < minFinger.y)  minFinger.y = fingerPos[f].y;
      if (fingerPos[f].z > maxFinger.z)  maxFinger.z = fingerPos[f].z;
      if (fingerPos[f].z < minFinger.z)  minFinger.z = fingerPos[f].z;
      
      // send OSC finger positions
      if (OSC_FINGERS)
        sendOSCMessage("/h"+(h+1)+"f"+(f+1)+"/", new float[]{fingerPos[f].x, fingerPos[f].y, fingerPos[f].z}); 
    }
    
    // get hand size and send thresholding data
    if (fingers.size() > 1)
      handSize[h] = PVector.dist(minFinger, maxFinger);
    if (OSC_HAND_SIZE) 
      sendOSCMessage("/h"+(h+1)+"d/", new float[]{handSize[h]});
    if (OSC_HAND_SIZE_TRIGGER) {
      if (handThresh[h]) {
        if (handSize[h] < HAND_THRESH_MIN)
          handThresh[h] = false;
          sendOSCMessage("/h"+(h+1)+"thresh0/");
      } else {
        if (handSize[h] > HAND_THRESH_MAX) {
          sendOSCMessage("/h"+(h+1)+"thresh1/");
          handThresh[h] = true;
          alph[h] = frameCount;
        }
      }
    }
    
    // draw bounding box  
    if (fingers.size() > 0) {
      minFinger.set(
        map(minFinger.x, 0, 1, -SIZE_BOX/2, SIZE_BOX/2), 
        map(minFinger.y, 1, 0, -SIZE_BOX/2, SIZE_BOX/2), 
        map(minFinger.z, 0, 1, -SIZE_BOX/2, SIZE_BOX/2));
      maxFinger.set(
        map(maxFinger.x, 0, 1, -SIZE_BOX/2, SIZE_BOX/2), 
        map(maxFinger.y, 1, 0, -SIZE_BOX/2, SIZE_BOX/2), 
        map(maxFinger.z, 0, 1, -SIZE_BOX/2, SIZE_BOX/2));      
      pushStyle();
      if (handThresh[h])
        strokeWeight(1+20*sin(map(constrain(frameCount-alph[h], 0, 20), 0, 20, 0, PI)));
      stroke(255-255*h, 255*h, 30, 180);
      noFill();

      PVector p = PVector.lerp(minFinger, maxFinger, 0.5);
      float d = PVector.dist(minFinger, maxFinger)/2;
      pushMatrix();
      translate(p.x, p.y, p.z);
      box(maxFinger.x-minFinger.x, maxFinger.y-minFinger.y, maxFinger.z-minFinger.z);
      popMatrix();
      popStyle();
    }
   
    // draw hand center
    pushStyle();
    noStroke();
    fill(100, 180, 100, 180);  
    pushMatrix();
    translate(map(handPosition[h].x, 0, 1, -SIZE_BOX/2, SIZE_BOX/2),
              map(handPosition[h].y, 1, 0, -SIZE_BOX/2, SIZE_BOX/2), 
              map(handPosition[h].z, 0, 1, -SIZE_BOX/2, SIZE_BOX/2));
    sphere(10);
    
    // draw palm axis
    rotateX(-pitch);
    rotateY(-yaw);
    rotateZ(-roll);
    strokeWeight(3);
    stroke(255, 0, 0);
    line(0, 0, 0, 0, 100, 0);
    stroke(0, 255, 0);
    line(0, 0, 0, 0, 0, 100);
    stroke(0, 0, 255);
    line(0, 0, 0, 100, 0, 0);    
    popMatrix();
    
    // draw fingers
    noStroke();
    fill(50, 50, 90, 180);    
    for (int f=0; f<fingers.size(); f++) {
      pushMatrix();
      translate(map(fingerPos[f].x, 0, 1, -SIZE_BOX/2, SIZE_BOX/2), 
                map(fingerPos[f].y, 1, 0, -SIZE_BOX/2, SIZE_BOX/2), 
                map(fingerPos[f].z, 0, 1, -SIZE_BOX/2, SIZE_BOX/2));
      sphere(6);      
      popMatrix();
    }
    popStyle();  
  }  
  popMatrix();

  // draw xy and xz planes
  translate(width-170, 20);
  rect(0, 0, 150, 150);
  rect(0, 180, 150, 150);  
  for (int h=0; h < min(2, hands.size()); h++) {
    ellipse(map(handPosition[h].x, 0, 1, 0, 150),
            map(handPosition[h].y, 1, 0, 0, 150), 10, 10);
    ellipse(map(handPosition[h].x, 0, 1, 0, 150),
            map(handPosition[h].z, 0, 1, 180, 330), 10, 10);
  }
}

public void swipeGestureRecognized(SwipeGesture gesture) {
  if (gesture.state() == State.STATE_STOP) {
    System.out.println("//////////////////////////////////////");
    System.out.println("Gesture type: " + gesture.type());
    System.out.println("ID: " + gesture.id());
    System.out.println("Position: " + leap.vectorToPVector(gesture.position()));
    System.out.println("Direction: " + gesture.direction());
    System.out.println("Duration: " + gesture.durationSeconds() + "s");
    System.out.println("Speed: " + gesture.speed());
    System.out.println("//////////////////////////////////////");
  } 
  else if (gesture.state() == State.STATE_START)
    sendOSCMessage("/h1swipe/");
  else if (gesture.state() == State.STATE_UPDATE) { }
}

void sendOSCMessage(String address, float[] values) {
  OscMessage msg = new OscMessage(address);
  for (int v=0; v<values.length; v++)
    msg.add(values[v]);
  oscP5.send(msg, myRemoteLocation);
}

void sendOSCMessage(String address) {
  oscP5.send(new OscMessage(address), myRemoteLocation);
}
  
void mouseDragged() {
  viewAngle.x += 0.005 * (mouseX - pmouseX);
  viewAngle.y -= 0.005 * (mouseY - pmouseY);
}

void stop() {
  oscP5.stop();
}

