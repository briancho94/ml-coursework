/*
THIS FILE WAS AUTOGENERATED! DO NOT EDIT!
file to edit: 10_mixup_ls.ipynb

*/



import Path
import TensorFlow

extension RandomDistribution {
    // Returns a batch of samples.
    func next<G: RandomNumberGenerator>(
        _ count: Int, using generator: inout G
    ) -> [Sample] {
        var result: [Sample] = []
        for _ in 0..<count {
            result.append(next(using: &generator))
        }
        return result
    }

    // Returns a batch of samples, using the global Threefry RNG.
    func next(_ count: Int) -> [Sample] {
        return next(count, using: &ThreefryRandomNumberGenerator.global)
    }
}

extension Learner {
    public class MixupDelegate: Delegate {
        private var distribution: BetaDistribution
        
        public init(alpha: Float = 0.4){
            distribution = BetaDistribution(alpha: alpha, beta: alpha)
        }
        
        override public func batchWillStart(learner: Learner) {
            if let xb = learner.currentInput {
                if let yb = learner.currentTarget as? Tensor<Float>{
                    var lambda = Tensor<Float>(distribution.next(Int(yb.shape[0])))
                    lambda = max(lambda, 1-lambda)
                    let shuffle = Raw.randomShuffle(value: Tensor<Int32>(0..<Int32(yb.shape[0])))
                    let xba = Raw.gather(params: xb, indices: shuffle)
                    let yba = Raw.gather(params: yb, indices: shuffle)
                    lambda = lambda.expandingShape(at: 1)
                    learner.currentInput = lambda * xb + (1-lambda) * xba
                    learner.currentTarget = (lambda * yb + (1-lambda) * yba) as? Label
                }
            }
        }
    }
    
    public func makeMixupDelegate(alpha: Float = 0.4) -> MixupDelegate {
        return MixupDelegate(alpha: alpha)
    }
}

@differentiable(wrt: out)
public func labelSmoothingCrossEntropy(_ out: TF, _ targ: TI, ε: Float = 0.1) -> TF {
    let c = out.shape[1]
    let loss = softmaxCrossEntropy(logits: out, labels: targ)
    let logPreds = logSoftmax(out)
    return (1-ε) * loss - (ε / Float(c)) * logPreds.mean()
}