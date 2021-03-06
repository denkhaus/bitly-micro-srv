package main

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/denkhaus/bitly-api-go"
	handler "github.com/denkhaus/microservices/bitly/proto"
	"github.com/juju/errors"
	"github.com/micro/cli"
	"github.com/micro/go-micro"

	"golang.org/x/net/context"
)

var (
	GitCommit = "undefined"
	Version   = "undefined"
)

type BitlyAPI struct {
	conn *bitly_api.Connection
}

func (p *BitlyAPI) Shorten(ctx context.Context, req *handler.Request, rsp *handler.Response) error {
	link, err := p.conn.Shorten(req.Url)
	if err != nil {
		return errors.Annotate(err, "shorten")
	}

	rsp.Url = link["url"].(string)
	return nil
}

func NewBitlyAPI(accessToken, secret string) *BitlyAPI {
	ba := BitlyAPI{
		conn: bitly_api.NewConnection(accessToken, secret),
	}

	return &ba
}

func main() {
	service := micro.NewService(
		micro.Flags(
			cli.StringFlag{
				Name:   "accessToken",
				Usage:  "Bitly API access token",
				EnvVar: "BITLY_ACCESS_TOKEN",
			},
			cli.StringFlag{
				Name:   "secret",
				Usage:  "Bitly API secret",
				EnvVar: "BITLY_SECRET",
			},
			cli.BoolFlag{
				Name:  "version",
				Usage: "Show version info",
			},
			cli.BoolFlag{
				Name:  "revision",
				Usage: "Show revision info",
			},
		),
		micro.Version(Version),
		micro.RegisterTTL(time.Second*30),
		micro.RegisterInterval(time.Second*10),
	)

	service.Init(
		micro.Action(func(c *cli.Context) {
			if c.Bool("version") {
				fmt.Printf("version: %s", Version)
				os.Exit(0)
			}
			if c.Bool("revision") {
				fmt.Printf("revision: %s", GitCommit)
				os.Exit(0)
			}

			accessToken := c.String("accessToken")
			if accessToken == "" {
				log.Fatal(errors.New("bitly access token undefined"))
			}

			secret := c.String("secret")

			ba := NewBitlyAPI(accessToken, secret)
			handler.RegisterBitlyHandler(service.Server(), ba)
		}),
	)

	if err := service.Run(); err != nil {
		log.Fatal(err)
	}
}
