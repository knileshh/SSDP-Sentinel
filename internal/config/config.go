package config

import (
    "github.com/spf13/viper"
)

// LoadConfig loads configuration from file
func LoadConfig(path string) error {
    viper.SetConfigFile(path)
    return viper.ReadInConfig()
}
