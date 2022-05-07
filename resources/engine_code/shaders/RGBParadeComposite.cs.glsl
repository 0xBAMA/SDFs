#version 430 core
layout( local_size_x = 8, local_size_y = 8, local_size_z = 1 ) in;

layout( binding = 3, r32ui ) uniform uimage2D redComposite;
layout( binding = 4, r32ui ) uniform uimage2D greenComposite;
layout( binding = 5, r32ui ) uniform uimage2D blueComposite;

layout( binding = 6, rgba8ui ) uniform uimage2D RGBCompositeOutput;

void main() {


}
