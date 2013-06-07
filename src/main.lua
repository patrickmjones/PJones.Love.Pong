-- Copyright (c) 2012 Patrick Jones http://patrickmjones.com
-- 
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
-- 
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
-- LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
-- OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- 
-- 
--
-- Controls:
--  Left Player: "a" moves paddle up, "z" moves paddle down
--  Right Player: "up" key moves paddle up, "down" key moves paddle down
--  "Spacebar" to serve the ball: 
--    NOTE: left player serves first and last scoring player serves thereafter
--
--
--
-- pjones-pong
function love.config(t)
    t.title = "Pong by Patrick Jones"
    t.author = "Patrick Jones"  
	t.version = "0.8.0"
	t.fullscreen = true
	t.screen.width = 800
	t.screen.height = 200
	t.release = true
	t.modules.joystick = false
	t.modules.physics = false
end

function love.load()
	screenX = love.graphics.getWidth()
	screenY = love.graphics.getHeight()
	singlePlayerMode = false
	showMenu = true

	-- Basic configuration
	gameconfig = {}
	gameconfig.quitKey = "escape"
	gameconfig.paddles = {}
	gameconfig.paddles.width = 15
	gameconfig.paddles.height = 70
	gameconfig.paddles.speed = 600
	gameconfig.ball = {}
	gameconfig.ball.vspeedmin = 50
	gameconfig.ball.vspeedmax = 600
	gameconfig.ball.speedinitial = 150
	gameconfig.ball.speedplus = 100
	gameconfig.buttons = {}
	gameconfig.buttons.height = 40
	gameconfig.buttons.width = 100
	gameconfig.buttons.Y = screenY * 0.5 - 20
	gameconfig.buttons.button1X = screenX*0.4 - (gameconfig.buttons.width * 0.5)
	gameconfig.buttons.button2X = screenX*0.6 - (gameconfig.buttons.width * 0.5)

	-- p1 specific config
	paddle1 = initialize_paddle()
	paddle1.upKey = "a"
	paddle1.downKey = "z"

	-- p2 specific config
	paddle2 = initialize_paddle()
	paddle2.x = screenX - gameconfig.paddles.width
	paddle2.upKey = "up"
	paddle2.downKey = "down"

	-- ball initialization
	ball = {}
	ball.inmotion = false
	ball.direction = "l"
	ball.vdirection = "d"
	ball.speed = gameconfig.ball.speedinitial
	ball.vspeed = 0
	ball.height = 10
	ball.width = 10

	recenter_ball()

	-- load necessary sound effects
	sounds = {}
	sounds.blip = love.audio.newSource( "blip.wav", "static" )
	sounds.score = love.audio.newSource( "score.wav", "static" )
end

-- This is the main logic part of the loop
function love.update(dt)
	if love.keyboard.isDown(gameconfig.quitKey) then
		showMenu = true
	elseif showMenu then		
		if love.mouse.isDown("l") then -- click!
			local mouseX, mouseY = love.mouse.getPosition()
			if mouseX > gameconfig.buttons.button1X 
				and mouseX < gameconfig.buttons.button1X + gameconfig.buttons.width 
				and mouseY > gameconfig.buttons.Y 
				and mouseY < gameconfig.buttons.Y + gameconfig.buttons.height then
					showMenu = false
					singlePlayerMode = true
			elseif mouseX > gameconfig.buttons.button2X 
				and mouseX < gameconfig.buttons.button2X + gameconfig.buttons.width 
				and mouseY > gameconfig.buttons.Y 
				and mouseY < gameconfig.buttons.Y + gameconfig.buttons.height then
					showMenu = false
					singlePlayerMode = false
			end
		end
	else
		move_paddle(paddle1, dt)

		if singlePlayerMode then
			ai_paddle_movement(paddle2, dt)
		else
			move_paddle(paddle2, dt)
		end

		-- press "space" to serve
		if ball.inmotion == false and love.keyboard.isDown(" ") then
			ball.inmotion = true
			ball.vspeed = math.random(gameconfig.ball.vspeedmin, gameconfig.ball.vspeedmax)
		end

		-- Move the ball as necessary
		if ball.inmotion == true then
			if ball.direction == "l" then
				ball.x = ball.x - ball.speed*dt			
			else
				ball.x = ball.x + ball.speed*dt
			end

			if ball.vdirection == "u" then
				ball.y = ball.y - ball.vspeed*dt
			else
				ball.y = ball.y + ball.vspeed*dt
			end
		end

		-- ball/paddle collision
		if ball.x < paddle1.x + paddle1.width and ball.y > paddle1.y and ball.y < paddle1.y + paddle1.height and not (ball.direction == "r") then
			paddle_collision()
		elseif ball.x > paddle2.x - 5 and ball.y > paddle2.y and ball.y < paddle2.y + paddle2.height and not (ball.direction == "l") then
			paddle_collision()
		end

		-- ball edge bouncing
		if ball.y < 0 then -- ball hit top of screen
			ball.vdirection = "d" 
		elseif ball.y > screenY - ball.height then -- ball hit bottom of screen
			ball.vdirection = "u"
		end

		-- See if anyone scored
		if ball.x < 0 then -- p2 scored!
			point_scored(paddle2) 
		elseif ball.x > screenX - ball.width then -- p1 scored!
			point_scored(paddle1)
		end
	end
end

-- Now that all the calculations are done, we just draw everything on screen
function love.draw()
	if showMenu then
		love.graphics.setBackgroundColor(70, 113, 213, 150)
		love.graphics.setColor(6, 38, 111, 150)
		love.graphics.rectangle("fill", gameconfig.buttons.button1X, gameconfig.buttons.Y, gameconfig.buttons.width, gameconfig.buttons.height)
		love.graphics.rectangle("fill", gameconfig.buttons.button2X, gameconfig.buttons.Y, gameconfig.buttons.width, gameconfig.buttons.height)

		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.print("1 Player", gameconfig.buttons.button1X + 25, gameconfig.buttons.Y + 12)
		love.graphics.print("2 Player", gameconfig.buttons.button2X + 25, gameconfig.buttons.Y + 12)
	else
		love.graphics.print(paddle1.score, screenX * 0.25, 5)
		love.graphics.print(paddle2.score, screenX * 0.75, 5)

		love.graphics.print("Player 1: '" .. paddle1.upKey .. "' to move up, '" .. paddle1.downKey .. "' to move down", screenX * 0.05, screenY - 20)
		if not singlePlayerMode then
			love.graphics.print("Player 2: '" .. paddle2.upKey .. "' to move up, '" .. paddle2.downKey .. "' to move down", screenX * 0.60, screenY - 20)
		end
		if not ball.inmotion then
			love.graphics.print("Press 'spacebar' to serve", screenX * 0.5 - 75, (screenY * 0.5) + 25)
		end
		love.graphics.setColor(255,255,255,255)
		love.graphics.rectangle("fill", paddle1.x, paddle1.y, paddle1.width, paddle1.height)
		love.graphics.rectangle("fill", paddle2.x, paddle2.y, paddle2.width, paddle2.height)
		love.graphics.rectangle("fill", ball.x, ball.y, ball.width, ball.height)
	end
end

-- Sets the ball to the center of the screen
function recenter_ball() 
	ball.x = (screenX * 0.5) - (ball.width * 0.5)
	ball.y = (screenY * 0.5) - (ball.height * 0.5)
end

-- Basic paddle setup
function initialize_paddle()
	local paddle = {}
	paddle.x = 0
	paddle.y = 0
	paddle.speed = gameconfig.paddles.speed
	paddle.height = gameconfig.paddles.height
	paddle.width = gameconfig.paddles.width
	paddle.score = 0
	return paddle
end

-- Check if a paddle's configured key is pressed for up or down and moves it accordlingly
function move_paddle(paddle, dt)
	if love.keyboard.isDown(paddle.upKey) then
		paddle.y = paddle.y - paddle.speed*dt
	elseif love.keyboard.isDown(paddle.downKey) then
		paddle.y = paddle.y + paddle.speed*dt
	end
	enforce_paddle_boundaries(paddle)
end

-- Ball has collided with a paddle, take appropriate action
function paddle_collision()
	-- bounce the ball back, if "r"ight then go "l"eft and vice versa
	if ball.direction == "l" then
		ball.direction = "r"
	else
		ball.direction = "l"
	end

	-- increase ball speed each time it is hit
	ball.speed = ball.speed + gameconfig.ball.speedplus

	-- randomize the vertical bounce
	ball.vspeed = math.random(gameconfig.ball.vspeedmin, gameconfig.ball.vspeedmax)	

	-- play sound
	love.audio.rewind(sounds.blip)
	love.audio.play(sounds.blip)
end

-- A point has been scored!
function point_scored(paddle)
	ball.inmotion = false
	ball.speed = gameconfig.ball.speedinitial
	recenter_ball()
	paddle.score = paddle.score + 1
	love.audio.rewind(sounds.score)
	love.audio.play(sounds.score)
end

-- Computer controlled paddle
function ai_paddle_movement(paddle, dt)
	-- paddle only reacts when ball is coming towards it
	if ball.direction == "r" then
		if ball.y < paddle.y + (paddle.height * 0.5) then
			paddle.y = paddle.y - paddle.speed*dt*0.7 -- ai moves at 70% of human speed
		elseif ball.y > paddle.y + (paddle.height * 0.5) then
			paddle.y = paddle.y + paddle.speed*dt
		end	
		enforce_paddle_boundaries(paddle)
	end
end

-- Enforces that the paddle does not go outside the screen
function enforce_paddle_boundaries(paddle)
 	if paddle.y < 0 then
		paddle.y = 0
	elseif paddle.y > screenY - paddle.height then
		paddle.y = screenY - paddle.height
	end
end

-- checks for keypresses, used for quit app
function love.keypressed(key)
   if key == gameconfig.quitKey then
      love.event.push("quit") 
   end
end

