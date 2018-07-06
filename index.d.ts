declare module "react-native-image-resizer" {
    export interface Response {
        path: string;
        uri: string;
        size?: number;
        name?: string;
    }
    export function createThumbnailImage(
        uri: string, width: number, height: number,
        format: "PNG" | "JPEG" | "WEBP", quality: number,
        rotation?: number, outputPath?: string
    ): Promise<Response>;
    
    export function createResizedImage(
        uri: string, width: number, height: number,
        format: "PNG" | "JPEG" | "WEBP", quality: number,
        rotation?: number, outputPath?: string
    ): Promise<Response>;
    
    export function tempPath(): Promise<Response>;
    export function exists(): Promise<Response>;
}
