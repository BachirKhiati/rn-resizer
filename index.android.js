import React from 'react-native';

const ImageResizerAndroid = React.NativeModules.ImageResizerAndroid;

export default {
  createResizedImage: (imagePath, newWidth, newHeight, compressFormat, quality, rotation = 0, outputPath) => {
    return new Promise((resolve, reject) => {
      ImageResizerAndroid.createResizedImage(imagePath, newWidth, newHeight,
        compressFormat, quality, rotation, outputPath, resolve, reject);
    });
  },
  createThumbnailImage: (imagePath, newWidth, newHeight, compressFormat, quality, rotation = 0, outputPath) => {
    return new Promise((resolve, reject) => {
      ImageResizerAndroid.createResizedImage(imagePath, newWidth, newHeight,
        compressFormat, quality, rotation, outputPath, resolve, reject);
    });
  },
  tempPath: () => {
    return new Promise((resolve, reject) => {
      ImageResizerAndroid.tempPath(resolve, reject);
    });
  },
  exists: (imagePath) => {
    return new Promise((resolve, reject) => {
      ImageResizerAndroid.exists(imagePath,resolve, reject);
    });
  }
};
