package systems

import (
    "reflect"
    "testing"
)

func TestCheckAddresses(t *testing.T) {
    tests := []struct {
        name     string
        addr     []string
        expected []string
    }{
        {
            name:     "IP without port",
            addr:     []string{"1.1.1.1"},
            expected: []string{"1.1.1.1:53"},
        },
        {
            name:     "IP with port already set",
            addr:     []string{"1.1.1.1:58"},
            expected: []string{"1.1.1.1:58"},
        },
        {
            name:     "Multiple IPs",
            addr:     []string{"1.1.1.1", "8.8.8.8:8", "111.111.111.111"},
            expected: []string{"1.1.1.1:53", "8.8.8.8:8", "111.111.111.111:53"},
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            ips := checkAddresses(tt.addr)
            if !reflect.DeepEqual(ips, tt.expected) {
                t.Errorf("Unexpected Result, expected %v, got %v", tt.expected, ips)
            }
        })
    }
}
