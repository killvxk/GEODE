#include <stdio.h>
#include <SDL2/SDL.h>

int main
(
    int    argc, 
    char **argv
)
{
    SDL_Window *window = NULL;
    SDL_Event       ev;

    (void) sizeof(argc);
    (void) sizeof(argv);
    printf("Hello, world!\n");

    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        printf("SDL_Init failed: %s\n", SDL_GetError());
        return 1;
    }
    if ((window = SDL_CreateWindow("Hello World!", 100, 100, 640, 480, SDL_WINDOW_SHOWN)) == NULL) {
        printf("SDL_CreateWindow failed: %s\n", SDL_GetError());
        return 1;
    }
    for ( ; ; ) {
        while (SDL_PollEvent(&ev)) {
            if (ev.type == SDL_QUIT) {
                goto cleanup_and_exit;
            }
        }
    }

cleanup_and_exit:
    SDL_Quit();
    return 0;
}
        
