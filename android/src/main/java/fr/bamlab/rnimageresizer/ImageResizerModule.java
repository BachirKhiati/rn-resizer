package fr.bamlab.rnimageresizer;

import android.content.Context;
import android.graphics.Bitmap;
import android.net.Uri;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;

import java.io.File;
import java.io.IOException;

/**
 * Created by almouro on 19/11/15.
 */
class ImageResizerModule extends ReactContextBaseJavaModule {
    private Context context;

    public ImageResizerModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.context = reactContext;
    }

    /**
     * @return the name of this module. This will be the name used to {@code require()} this module
     * from javascript.
     */
    @Override
    public String getName() {
        return "ImageResizerAndroid";
    }

    @ReactMethod
    public void createResizedImage(String imagePath, int newWidth, int newHeight, String compressFormat,
                            int quality, int rotation, String outputPath, final Callback successCb, final Callback failureCb) {
        try {
            createResizedImageWithExceptions(imagePath, newWidth, newHeight, compressFormat, quality,
                    rotation, outputPath, successCb, failureCb);
        } catch (IOException e) {
            failureCb.invoke(e.getMessage());
        }
    }

    @ReactMethod
    public void tempPath(final Callback successCb, final Callback failureCb) {
        try {
            createtempPathWithExceptions(successCb, failureCb);
        } catch (IOException e) {
            failureCb.invoke(e.getMessage());
        }
    }

    @ReactMethod
    public void exists(String filepath,final Callback successCb, final Callback failureCb) {
      try {
        File file = new File(filepath+ ".JPEG");
        successCb.invoke(file.exists());
      } catch (Exception ex) {
        ex.printStackTrace();
        failureCb.invoke("Error File check", filepath, ex);
      }
    }

    private void createResizedImageWithExceptions(String imagePath, int newWidth, int newHeight,
                                           String compressFormatString, int quality, int rotation, String outputPath,
                                           final Callback successCb, final Callback failureCb) throws IOException {
        Bitmap.CompressFormat compressFormat = Bitmap.CompressFormat.valueOf(compressFormatString);
        Uri imageUri = Uri.parse(imagePath);

        File resizedImage = ImageResizer.createResizedImage(this.context, imageUri, newWidth,
                newHeight, compressFormat, quality, rotation, outputPath);

        // If resizedImagePath is empty and this wasn't caught earlier, throw.
        if (resizedImage.isFile()) {
            WritableMap response = Arguments.createMap();
            response.putString("path", resizedImage.getAbsolutePath());
            response.putString("uri", Uri.fromFile(resizedImage).toString());
            response.putString("name", resizedImage.getName());
            response.putDouble("size", resizedImage.length());
            // Invoke success
            successCb.invoke(response);
        } else {
            failureCb.invoke("Error getting resized image path");
        }
    }
    private void createtempPathWithExceptions(final Callback successCb, final Callback failureCb) throws IOException {
        File path = this.context.getCacheDir(); 
        if (path.isDirectory()) {
            WritableMap response = Arguments.createMap();
            response.putString("path", path.getAbsolutePath());
            response.putString("uri", Uri.fromFile(path).toString());
            // Invoke success
            successCb.invoke(response);
        } else {
            failureCb.invoke("Error getting resized image path");
        }
    }
}
