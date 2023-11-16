# Demo1 Example

Example shows the use of the global generator. It has two target types:
- Target_U5 (for STMicroelectronics B-U585I-IOT02A)
- Target_H7 (for STMicroelectronics STM32H723ZGTx)

Each target has its own associated project. Each project contains the component Device:CubeMX, that have `<generator-id\>` CubeMX to run the STM32CubeMX generator.
STM32CubeMX generated files are located on default location - `$SolutionDir()$/STM32CubeMX/$TargetType$`.

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
csolution run -g CubeMX .\test.csolution.yml -c u5.Debug+Target_U5 
```
STM32CubeMX generated files location:
- [./Demo1/STM32CubeMX/Target_U5](./STM32CubeMX/Target_U5) (for Target_U5)
- [./Demo1/STM32CubeMX/Target_H7](./STM32CubeMX/Target_H7) (for Target_H7)
