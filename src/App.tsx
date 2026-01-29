import { useEffect, useState } from 'react';
import axios from 'axios';

import reactLogo from './assets/react.svg';
import viteLogo from '/vite.svg';
import './App.css';

function App() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    const fetchCheer = async () => {
      try {
        const res = await axios.get('http://localhost:3000/api/count');
        setCount(res.data.count);
      } catch (error) {
        console.error('API 호출 실패:', error);
      }
    };

    fetchCheer();
  }, []);

  const handleCheer = async () => {
    try {
      const res = await axios.post('http://localhost:3000/api/count');
      setCount(res.data.count);
    } catch (error) {
      console.error('응원 실패:', error);
    }
  };

  return (
    <>
      <div>
        <a href='https://vite.dev' target='_blank'>
          <img src={viteLogo} className='logo' alt='Vite logo' />
        </a>
        <a href='https://react.dev' target='_blank'>
          <img src={reactLogo} className='logo react' alt='React logo' />
        </a>
      </div>

      <h1>3조를 응원해주세요</h1>
      <div className='card'>
        <button onClick={handleCheer}>지금까지의 응원 {count}</button>
      </div>
    </>
  );
}

export default App;
