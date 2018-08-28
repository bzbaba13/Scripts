package main

// A simple program to provide the inquired nth day-of-week of a month.

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
	day       int
	found     bool
)

func init() {
	t := time.Now()
	flag.IntVar(&year, "y", t.Year(), "4-digit year, e.g., 2018")
	flag.StringVar(&month, "m", t.Month().String(), "3+ characters month, e.g., jan, feb, etc.")
	flag.IntVar(&nth, "n", 1, "1-digit instance, e.g., 1 for 1st, 2 for 2nd, etc.")
	flag.StringVar(&dayofweek, "d", t.Weekday().String(), "3+ characters day-of-week, e.g., mon, tue, etc.")
}

func setupMonth(Month string) int {
	switch {
	case strings.Contains(Month, "jan"):
		return 1
	case strings.Contains(Month, "feb"):
		return 2
	case strings.Contains(Month, "mar"):
		return 3
	case strings.Contains(Month, "apr"):
		return 4
	case strings.Contains(Month, "may"):
		return 5
	case strings.Contains(Month, "jun"):
		return 6
	case strings.Contains(Month, "jul"):
		return 7
	case strings.Contains(Month, "aug"):
		return 8
	case strings.Contains(Month, "sep"):
		return 9
	case strings.Contains(Month, "oct"):
		return 10
	case strings.Contains(Month, "nov"):
		return 11
	case strings.Contains(Month, "dec"):
		return 12
	}
	return 99
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

func setupInstance(n int) string {
	switch n {
	case 1:
		return "1st"
	case 2:
		return "2nd"
	case 3:
		return "3rd"
	case 4:
		return "4th"
	case 5:
		return "5th"
	case 6:
		return "6th"
	}
	return "9th"
}

func main() {
	flag.Parse()
	myMonth := setupMonth(strings.ToLower(month))
	myDoW := setupDayOfWeek(strings.ToLower(dayofweek))
	for day := 0; day < 32; day++ {
		d := time.Date(year, time.Month(myMonth), day, 0, 0, 0, 0, time.UTC)
		if cal.IsWeekdayN(d, time.Weekday(myDoW), nth) {
			fmt.Printf("The %s %s of %s in year %d is: %s %d, %d.\n",
				setupInstance(nth),
				time.Weekday(myDoW),
				time.Month(myMonth),
				year,
				time.Month(myMonth),
				day,
				year)
			found = true
			break
		}
	}
	if !found {
		fmt.Println("Unable to determine answer with provided informaiton of:")
		fmt.Printf("Year: %d, Month: %s, Day-of-week: %s, & Instance: %d\n",
			year, month, dayofweek, nth)
	}
}
