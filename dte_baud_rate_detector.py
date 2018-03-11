#!/usr/bin/env python

import serial

class DTEBaudRateDetector:
    """
        This class is used to test what the appropriate DTE (Data Terminal Equipment)
        baud rate is (i.e., the baud rate needed between your computer and the modem,
        not the baud rate between your modem and the Dreamcast modem).
    """

    # Kazade found that some modems work better with a DTE speed of 56000bps, so
    # that's the first one we try even though 115200bps would be preferable.
    BAUD_RATES = [56000, 115200, 57600, 33600]

    def __init__(self, serial_port, logger):
        """
        Parameters
        ----------
        serial_port : str
            The serial port to use, without the `/dev/`
            part.
        logger : Logger
            A working logger
        """

        self._logger              = logger
        self._serial_port         = serial_port
        self._supported_baud_rate = None

    @property
    def logger(self):
        return self._logger

    @property
    def serial_port(self):
        return self._serial_port

    def supported_baud_rate(self):
        """
            This method attempts to initialize the serial port with the baud rates
            defined earlier. Once one is detected successfully, we cache the result.
            If all baud rates fail, this method will raise an error.
        """

        if self._supported_baud_rate is not None:
            return self._supported_baud_rate

        ser = None

        for baud in self.BAUD_RATES:
            try:
                self._logger.info("Testing /dev/{} with DTE baud rate {}".format(self._serial_port, baud))
                ser = serial.Serial("/dev/{}".format(self._serial_port), baud, timeout=0)
                self._logger.info("Baud rate {} worked!".format(baud))

                # Cache the baud rate and return it
                self._supported_baud_rate = baud
                return self._supported_baud_rate
            except ValueError:
                self._logger.info("Baud rate {} didn't work, trying a different one.".format(baud))
            finally:
                # Don't leak the serial port
                if ser and ser.isOpen():
                    ser.close()

                ser = None

        logger.error("None of the baud rates tested worked for /dev/{}.".format(self._serial_port))
        raise ValueError("None of the baud rates tested work with your equipment. DreamPi cannot start. Please report this at https://github.com/Kazade/dreampi.")


