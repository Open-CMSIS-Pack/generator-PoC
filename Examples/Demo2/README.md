# Demo2 Example

Example shows the use of the global generator in combination with board layer. It has one target type:
-  B-U585I-IOT02A (for STMicroelectronics B-U585I-IOT02A)

with two projects:
- [secure.cproject.yml](./secure/secure.cproject.yml)
- [nonsecure.cproject.yml](./nonsecure/nonsecure.cproject.yml)

Each project contains its own board layer:
- [secure board layer](./layer/Board/B-U585I-IOT02A_secure/Board.clayer.yml)
- [nonsecure board layer](./layer/Board/B-U585I-IOT02A_nonsecure/Board.clayer.yml)

and each board layer contains the component Device:CubeMX, that have `<generator-id>` CubeMX to run the STM32CubeMX generator. Output location for STM32CubeMX generated files is set with `generators` node in board layers: 

```
  generators:
    options:
    - generator: CubeMX
      path: ../STM32CubeMX
```

## Prerequisites

### Tools:
 - [CMSIS-Toolbox 2.2.0 - extgen3](https://github.com/brondani/cmsis-toolbox/releases/tag/2.2.0-extgen3/) or later
 - [generator-bridge v0.9.1](https://github.com/Open-CMSIS-Pack/generator-bridge/releases/tag/v0.9.1) or later


## Run Generator
Following command lists generators (with output directories):
```sh
csolution list generators -v .\test.csolution.yml
```

Following command runs generator CubeMX:
```sh
csolution run -g CubeMX .\test.csolution.yml -c nonsecure.Debug+B-U585I-IOT02A
```
STM32CubeMX generated files location:
- [./layer/Board/STM32CubeMX](./layer/Board/STM32CubeMX)

