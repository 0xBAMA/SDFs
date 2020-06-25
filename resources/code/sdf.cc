#include "sdf.h"
// This contains the very high level expression of what's going on

sdf::sdf()
{
    pquit = false;

    create_window();

    while(!pquit)
    {
        draw_everything();
    }
}

sdf::~sdf()
{
    quit();
}
