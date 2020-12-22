// Note: the original name of YUVToRGBConversion.swift for this file chokes the compiler on Linux for some reason

// BT.601, which is the standard for SDTV.
public let colorConversionMatrix601Default = Matrix3x3(rowMajorValues:[
    1.164,  1.164, 1.164,
    0.0, -0.392, 2.017,
    1.596, -0.813,   0.0
])

// BT.601 full range (ref: http://www.equasys.de/colorconversion.html)
public let colorConversionMatrix601FullRangeDefault = Matrix3x3(rowMajorValues:[
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
])

// BT.709, which is the standard for HDTV.
public let colorConversionMatrix709Default = Matrix3x3(rowMajorValues:[
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
])

public func convertYUVToRGB(shader:ShaderProgram, luminanceFramebuffer:Framebuffer, chrominanceFramebuffer:Framebuffer, secondChrominanceFramebuffer:Framebuffer? = nil, resizeOutput: ResizeOutputInfo? = nil, resultFramebuffer:Framebuffer, colorConversionMatrix:Matrix3x3) {
    let textureProperties:[InputTextureProperties]
    let luminanceTextureProperties: InputTextureProperties
    let chrominanceTextureProperties: InputTextureProperties
    var secondChrominanceTextureProperties: InputTextureProperties?
    if let resizeOutput = resizeOutput {
        luminanceTextureProperties = InputTextureProperties(textureCoordinates:luminanceFramebuffer.orientation.rotationNeededForOrientation(resultFramebuffer.orientation).croppedTextureCoordinates(offsetFromOrigin:resizeOutput.normalizedOffsetFromOrigin, cropSize:resizeOutput.normalizedCropSize), texture:luminanceFramebuffer.texture)
        chrominanceTextureProperties = InputTextureProperties(textureCoordinates:chrominanceFramebuffer.orientation.rotationNeededForOrientation(resultFramebuffer.orientation).croppedTextureCoordinates(offsetFromOrigin:resizeOutput.normalizedOffsetFromOrigin, cropSize:resizeOutput.normalizedCropSize), texture:chrominanceFramebuffer.texture)
        if let secondChrominanceFramebuffer = secondChrominanceFramebuffer {
            secondChrominanceTextureProperties = InputTextureProperties(textureCoordinates:secondChrominanceFramebuffer.orientation.rotationNeededForOrientation(resultFramebuffer.orientation).croppedTextureCoordinates(offsetFromOrigin:resizeOutput.normalizedOffsetFromOrigin, cropSize:resizeOutput.normalizedCropSize), texture:secondChrominanceFramebuffer.texture)
        }
    } else {
        luminanceTextureProperties = luminanceFramebuffer.texturePropertiesForTargetOrientation(resultFramebuffer.orientation)
        chrominanceTextureProperties = chrominanceFramebuffer.texturePropertiesForTargetOrientation(resultFramebuffer.orientation)
        if let secondChrominanceFramebuffer = secondChrominanceFramebuffer {
            secondChrominanceTextureProperties = secondChrominanceFramebuffer.texturePropertiesForTargetOrientation(resultFramebuffer.orientation)
        }
    }
    
    if let secondChrominanceTextureProperties = secondChrominanceTextureProperties {
        textureProperties = [luminanceTextureProperties, chrominanceTextureProperties, secondChrominanceTextureProperties]
    } else {
        textureProperties = [luminanceTextureProperties, chrominanceTextureProperties]
    }
    resultFramebuffer.activateFramebufferForRendering()
    clearFramebufferWithColor(Color.black)
    var uniformSettings = ShaderUniformSettings()
    uniformSettings["colorConversionMatrix"] = colorConversionMatrix
    renderQuadWithShader(shader, uniformSettings:uniformSettings, vertexBufferObject:sharedImageProcessingContext.standardImageVBO, inputTextures:textureProperties)
    luminanceFramebuffer.unlock()
    chrominanceFramebuffer.unlock()
    secondChrominanceFramebuffer?.unlock()
}
