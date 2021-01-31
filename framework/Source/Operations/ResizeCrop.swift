public struct ResizeOutputInfo {
    // size in pixel
    let finalCropSize: Size
    // normalized size within [0, 1] of inputSize
    let normalizedCropSize: Size
    // normalized offset to [0, 1] of inputSize
    let normalizedOffsetFromOrigin: Position
}

public func limitedSizeAndRatio(of inputSize: Size, to maxSize: Size) -> ResizeOutputInfo {
    // Aspect fit maxSize to inputSize to get normalized size and offset
    let aspectFitRatio = min(inputSize.width / maxSize.width, inputSize.height / maxSize.height)
    let cropSizeInInput = Size(width: maxSize.width * aspectFitRatio, height: maxSize.height * aspectFitRatio)
    let normalizedCropSize = Size(width: cropSizeInInput.width / inputSize.width, height: cropSizeInInput.height / inputSize.height)
    let normalizedOffsetFromOrigin = Position((inputSize.width - cropSizeInInput.width) / 2 / inputSize.width,
                                              (inputSize.height - cropSizeInInput.height) / 2 / inputSize.height)
    
    let finalCropSize: Size
    if inputSize.width < maxSize.width && inputSize.height < maxSize.height {
        // inputSize is smaller, use cropSizeInInput as finalCropSize
        finalCropSize = cropSizeInInput
    } else {
        // inputSize is larger, use maxSize as finalCropSize
        finalCropSize = maxSize
    }
    return ResizeOutputInfo(finalCropSize: finalCropSize, normalizedCropSize: normalizedCropSize, normalizedOffsetFromOrigin: normalizedOffsetFromOrigin)
}

public func calculateResizeOutput(inputSize: Size, outputSize: Size?, scaleOutputSizeToFill: Bool) -> ResizeOutputInfo {
    let finalCropSize: Size
    let normalizedCropSize: Size
    let normalizedOffsetFromOrigin: Position

    if let outputSize = outputSize {
        if scaleOutputSizeToFill {
            // finalCropSize won't be resized
            let ratioW = outputSize.width / inputSize.width
            let ratioH = outputSize.height / inputSize.height
            if ratioW > ratioH {
                finalCropSize = Size(width: inputSize.width, height: inputSize.width * (outputSize.height / outputSize.width))
            } else {
                finalCropSize = Size(width: inputSize.height * (outputSize.width / outputSize.height), height: inputSize.height)
            }
        } else {
            // finalCropSize might be resized
            finalCropSize = outputSize
        }
        
        // Scale finalCropSize to inputSize to crop original content
        let aspectFitRatioToOrigin = min(inputSize.width / finalCropSize.width, inputSize.height / finalCropSize.height)
        let cropSizeInOrigin = Size(width: finalCropSize.width * aspectFitRatioToOrigin, height: finalCropSize.height * aspectFitRatioToOrigin)
        normalizedCropSize = Size(width: cropSizeInOrigin.width / inputSize.width, height: cropSizeInOrigin.height / inputSize.height)
        normalizedOffsetFromOrigin = Position((inputSize.width - cropSizeInOrigin.width) / 2 / inputSize.width,
                                              (inputSize.height - cropSizeInOrigin.height) / 2 / inputSize.height)
    } else {
        finalCropSize = inputSize
        normalizedOffsetFromOrigin = Position.zero
        normalizedCropSize = Size(width: 1, height: 1)
    }
    
    return ResizeOutputInfo(finalCropSize: finalCropSize, normalizedCropSize: normalizedCropSize, normalizedOffsetFromOrigin: normalizedOffsetFromOrigin)
}

open class ResizeCrop: BasicOperation {
    public var useCropSizeAsFinal = false
    public var cropSizeInPixels: Size?
    
    public init() {
        super.init(fragmentShader: PassthroughFragmentShader, numberOfInputs: 1)
    }
    
    override open func renderFrame() {
        let inputFramebuffer: Framebuffer = inputFramebuffers[0]!
        let inputGLSize = inputFramebuffer.sizeForTargetOrientation(.portrait)
        let inputSize = Size(inputGLSize)

        let resizeOutputInfo = calculateResizeOutput(inputSize: inputSize, outputSize: cropSizeInPixels, scaleOutputSizeToFill: !useCropSizeAsFinal)

        renderFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(
            orientation: .portrait,
            size: GLSize(resizeOutputInfo.finalCropSize),
            stencil: false)
        
        let textureProperties = InputTextureProperties(textureCoordinates: inputFramebuffer.orientation.rotationNeededForOrientation(.portrait).croppedTextureCoordinates(offsetFromOrigin: resizeOutputInfo.normalizedOffsetFromOrigin, cropSize: resizeOutputInfo.normalizedCropSize), texture: inputFramebuffer.texture)
        
        renderFramebuffer.activateFramebufferForRendering()
        clearFramebufferWithColor(backgroundColor)
        renderQuadWithShader(shader, uniformSettings: uniformSettings, vertexBufferObject: sharedImageProcessingContext.standardImageVBO, inputTextures: [textureProperties])
        releaseIncomingFramebuffers()
    }
}

extension GLSize {
    var gpuSize: Size {
        return Size(width: Float(width), height: Float(height))
    }
}
