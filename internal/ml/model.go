package ml

import "github.com/sirupsen/logrus"

// Model interface for ML predictions
type Model interface {
    LoadModel(path string) error
    Predict(features []float64) (*Prediction, error)
}

// Prediction represents ML model output
type Prediction struct {
    IsMalicious bool
    Confidence  float64
    Label       string
}
