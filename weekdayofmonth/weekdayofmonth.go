// A simple program to provide the inquired nth day-of-week of a month.
package main

import (
	"flag"
	"fmt"
	"strings"
	"time"

	"github.com/rickar/cal"
)

var (
	msg       []string
	year      int
	month     string
	nth       int
	dayofweek string
)

func init() {
	t := time.Now()
	flag.IntVar(&year, "year", t.Year(), "4-digit year, e.g., 2018")
	flag.StringVar(&month, "month", t.Month().String(), "3+ characters month, e.g., jan, feb, etc.")
	flag.IntVar(&nth, "nth", 1, "1-digit instance, e.g., 1 for 1st, 2 for 2nd, etc.")
	flag.StringVar(&dayofweek, "dayofweek", t.Weekday().String(), "3+ characters day-of-week, e.g., mon, tue, etc.")
}

func setupDayOfWeek(DoW string) int {
	switch {
	case strings.Contains(DoW, "sun"):
		return 0
	case strings.Contains(DoW, "mon"):
		return 1
	case strings.Contains(DoW, "tue"):
		return 2
	case strings.Contains(DoW, "wed"):
		return 3
	case strings.Contains(DoW, "thu"):
		return 4
	case strings.Contains(DoW, "fri"):
		return 5
	case strings.Contains(DoW, "sat"):
		return 6
	}
	return 9
}

func main() {
	//	d := time.Now()
	flag.Parse()
	d := time.Date(2018, 8, 1, 0, 0, 0, 0, time.UTC)
	fmt.Printf("%v\n", d)
	if cal.IsWeekdayN(d, 3, 2) {
		fmt.Printf("%s\n", "good")
	} else {
		fmt.Printf("%s\n", "bad")
	}
}
