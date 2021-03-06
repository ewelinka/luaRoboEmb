--AX12 high level methods
local ax12api = require("ax12")

--Atributos
local ax12motor ={
	ax12=nil,
	ttyFile = "/dev/ttyUSB0",
	motor_id=nil
}

ax12motor.debugprint = print --for debug
--ax12motor.debugprint = function() end  --do not print anything by default


--Constructor
function ax12motor:new (o)
  o = o or {}   -- create object if user does not provide one
  --OO cookbook
  setmetatable(o, self)
  self.__index = self
  --inicialización específica
  o:init()
  
  return o
end

--Inicialización
function ax12motor:init()
	if ax12motor.ax12 == nil  then 
		--configurar librería serial
		ax12motor.ax12 = ax12api:new({ttyFile=ttyFile})
	end	
end

--Inicialización para funcionamiento como rotación continua
function ax12motor:initContinuousRotation()
	-- 0x06 dirección de config de límites de ángulos (se setean en 0 los límites)
	self.ax12:writeData(self.motor_id,0x06,{0x00,0x00,0x00,0x00})
end

function ax12motor:ping()
	local err = self.ax12:ping(self.motor_id)
	ax12motor.debugprint("ping return " .. err)
end


--value=1 prende, value=0 apaga
function ax12motor:setLedValue(value)
	self.ax12:writeData(self.motor_id,0x19,{value})
end

function ax12motor:getId()
	--Se lee dirección 0x3, 1 byte
	local ret, err = self.ax12:readData(self.motor_id,0x3,1)
	return ret[1]
end

--metodo de clase (solo funciona con broadcast)
function ax12motor.setId(id)
	--se asume que solo un motor esta conectado	
	ax12api.ax12:writeData(nil,0x3,{id})
end

function ax12motor:getSpeed()
	local velArray , err = self.ax12:readData(self.motor_id,0x26,2)
	local b1 = velArray[1]
	local b2 = velArray[2]
	ax12motor.debugprint("getSpeed " .. b1 .." " .. b2)
	local vel = ( b1 + (b2 % 4)*256) * (-1) ^ (math.floor(b2/4)%2)
	return vel
end

function ax12motor:setSpeed(vel)
	local b1 = math.abs(vel) % 256
	local b2 = math.floor(math.abs(vel) / 256)
	if b2 > 3 then b2 = 3 end
	if vel < 0 then
		b2 = b2 + 4
	end
	ax12motor.debugprint("setSpeed " .. b1 .." " .. b2)
	self.ax12:writeData(self.motor_id,0x20,{b1,b2})
end

function ax12motor:getOperatingVoltage()
	local voltArr , err = self.ax12:readData(self.motor_id,0x0C,2)
	local voltMin = voltArr[1]/10
	local voltMax = voltArr[2]/10
	ax12motor.debugprint("getOperatingVoltage " .. voltMin .. " - " .. voltMax)
	return voltMin, voltMax
end
function ax12motor:setOperatingVoltage(vMin,vMax)
	local vMinByte = vMin *10
	local vMaxByte = vMax *10
	local err = self.ax12:writeData(self.motor_id,0x0C,{vMinByte,vMaxByte})
	ax12motor.debugprint("setOperatingVoltage " .. vMinByte .." " .. vMaxByte .. " error: " .. err)
end
function ax12motor:getCurrentVoltage()
	local voltArr , err = self.ax12:readData(self.motor_id,0x2A,1)
	local volt = voltArr[1]/10
	ax12motor.debugprint("currentVoltage " .. volt)
	return volt
end

--TODO
function ax12motor:getMaxTorque()
end
function ax12motor:setMaxTorque(torque)
end
function ax12motor:getPosition()
	--readData(id,0x24,2)
end



return ax12motor
